resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  dynamic "origin" {
    for_each = var.origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id

      # S3 static website hosting buckets must be accessed as custom origins rather than S3 origins
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "http-only" # S3 website endpoints only support HTTP
        origin_ssl_protocols     = ["TLSv1.2"]
      }

      dynamic "custom_header" {
        for_each = var.referer_secret != "" ? [1] : []
        content {
          name  = "Referer"
          value = var.referer_secret
        }
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.default_target_origin_id

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    # Ignore changes to the target origin ID because the deploy-blue-green script will switch it dynamically
    ignore_changes = [
      default_cache_behavior[0].target_origin_id
    ]
  }

  tags = {
    Environment = var.env
  }
}
