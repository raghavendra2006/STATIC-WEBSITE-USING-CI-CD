output "bucket_id" {
  value       = aws_s3_bucket.site.id
  description = "The S3 bucket ID"
}

output "bucket_arn" {
  value       = aws_s3_bucket.site.arn
  description = "The S3 bucket ARN"
}

output "website_endpoint" {
  value       = aws_s3_bucket_website_configuration.site_config.website_endpoint
  description = "The S3 static site website endpoint URL"
}

output "website_domain" {
  value       = aws_s3_bucket_website_configuration.site_config.website_domain
  description = "The domain name of the S3 website endpoint"
}
