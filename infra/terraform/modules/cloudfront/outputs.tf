output "dist_id" {
  value       = aws_cloudfront_distribution.site.id
  description = "The ID of the CloudFront distribution"
}

output "domain_name" {
  value       = aws_cloudfront_distribution.site.domain_name
  description = "The domain name of the CloudFront distribution"
}
