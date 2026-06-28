output "staging_url" {
  value       = "https://${module.cloudfront_staging.domain_name}"
  description = "The URL of the staging environment fronted by CloudFront"
}

output "production_url" {
  value       = "https://${module.cloudfront_prod.domain_name}"
  description = "The URL of the production environment fronted by CloudFront"
}

output "staging_bucket_name" {
  value       = module.s3_staging.bucket_id
  description = "The name of the staging S3 bucket"
}

output "prod_blue_bucket_name" {
  value       = module.s3_prod_blue.bucket_id
  description = "The name of the prod-blue S3 bucket"
}

output "prod_green_bucket_name" {
  value       = module.s3_prod_green.bucket_id
  description = "The name of the prod-green S3 bucket"
}

output "cloudfront_staging_distribution_id" {
  value       = module.cloudfront_staging.dist_id
  description = "The Staging CloudFront Distribution ID"
}

output "cloudfront_prod_distribution_id" {
  value       = module.cloudfront_prod.dist_id
  description = "The Production CloudFront Distribution ID"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The AWS IAM Role ARN for GitHub Actions OIDC"
}

output "ssm_parameter_active_color_name" {
  value       = aws_ssm_parameter.active_color.name
  description = "The SSM parameter path tracking the active production color"
}
