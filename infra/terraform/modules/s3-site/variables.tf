variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket to create"
}

variable "env" {
  type        = string
  description = "Environment name (staging, prod-blue, prod-green)"
}

variable "referer_secret" {
  type        = string
  description = "Secret value sent in CloudFront Referer header to restrict direct S3 access. If empty, bucket is publicly readable."
  default     = ""
}
