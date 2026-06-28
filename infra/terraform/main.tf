terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Unique suffix for S3 buckets
resource "random_id" "suffix" {
  byte_length = 4
}

# Auto-generated referer secret header value
resource "random_password" "referer_secret" {
  length  = 32
  special = false
}

# Staging S3 Bucket
module "s3_staging" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-staging-${random_id.suffix.hex}"
  env            = "staging"
  referer_secret = random_password.referer_secret.result
}

# Prod Blue S3 Bucket
module "s3_prod_blue" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-prod-blue-${random_id.suffix.hex}"
  env            = "prod-blue"
  referer_secret = random_password.referer_secret.result
}

# Prod Green S3 Bucket
module "s3_prod_green" {
  source         = "./modules/s3-site"
  bucket_name    = "${var.project_name}-prod-green-${random_id.suffix.hex}"
  env            = "prod-green"
  referer_secret = random_password.referer_secret.result
}

# Staging CloudFront Distribution
module "cloudfront_staging" {
  source                   = "./modules/cloudfront"
  env                      = "staging"
  referer_secret           = random_password.referer_secret.result
  default_target_origin_id = "staging-s3-origin"
  origins = [
    {
      origin_id   = "staging-s3-origin"
      domain_name = module.s3_staging.website_endpoint
    }
  ]
}

# Production CloudFront Distribution
module "cloudfront_prod" {
  source                   = "./modules/cloudfront"
  env                      = "prod"
  referer_secret           = random_password.referer_secret.result
  default_target_origin_id = "prod-blue-origin" # Initial target is blue
  origins = [
    {
      origin_id   = "prod-blue-origin"
      domain_name = module.s3_prod_blue.website_endpoint
    },
    {
      origin_id   = "prod-green-origin"
      domain_name = module.s3_prod_green.website_endpoint
    }
  ]
}

# SSM Parameter to track active blue-green environment color
resource "aws_ssm_parameter" "active_color" {
  name        = "/site/${var.project_name}/prod-active-color"
  type        = "String"
  value       = "blue"
  description = "Tracks the active prod environment color (blue or green)"

  lifecycle {
    # Ignore changes to value so that deployments via scripts don't get reverted by TF
    ignore_changes = [value]
  }
}

# GitHub Actions OIDC Provider Setup
# Checks if provider already exists; standard AWS OIDC thumbprint for GitHub.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c587750275631c5b88820c784f1837ff221350a"]
}

# IAM Role for GitHub Actions CI/CD pipeline to assume via OIDC
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

# IAM Policy for GitHub Actions with strictly scoped access
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.project_name}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3SyncAccess"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation"
        ]
        Resource = [
          module.s3_staging.bucket_arn,
          "${module.s3_staging.bucket_arn}/*",
          module.s3_prod_blue.bucket_arn,
          "${module.s3_prod_blue.bucket_arn}/*",
          module.s3_prod_green.bucket_arn,
          "${module.s3_prod_green.bucket_arn}/*"
        ]
      },
      {
        Sid      = "CloudFrontInvalidationAccess"
        Effect   = "Allow"
        Action   = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetInvalidation",
          "cloudfront:GetDistribution",
          "cloudfront:GetDistributionConfig",
          "cloudfront:UpdateDistribution"
        ]
        Resource = [
          "arn:aws:cloudfront::*:distribution/${module.cloudfront_staging.dist_id}",
          "arn:aws:cloudfront::*:distribution/${module.cloudfront_prod.dist_id}"
        ]
      },
      {
        Sid      = "SSMParameterAccess"
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = aws_ssm_parameter.active_color.arn
      }
    ]
  })
}
