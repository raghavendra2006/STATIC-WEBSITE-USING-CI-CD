resource "aws_s3_bucket" "site" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name        = var.bucket_name
    Environment = var.env
  }
}

resource "aws_s3_bucket_website_configuration" "site_config" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "site_access" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "site_policy" {
  bucket = aws_s3_bucket.site.id
  depends_on = [
    aws_s3_bucket_public_access_block.site_access
  ]

  policy = data.aws_iam_policy_document.site_policy_doc.json
}

data "aws_iam_policy_document" "site_policy_doc" {
  statement {
    sid       = "AllowCloudFrontAccessOnly"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    dynamic "condition" {
      for_each = var.referer_secret != "" ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:Referer"
        values   = [var.referer_secret]
      }
    }
  }
}
