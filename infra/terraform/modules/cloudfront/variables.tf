variable "env" {
  type        = string
  description = "Environment name (staging, prod)"
}

variable "origins" {
  type = list(object({
    origin_id   = string
    domain_name = string
  }))
  description = "List of S3 website endpoints to configure as origins"
}

variable "default_target_origin_id" {
  type        = string
  description = "The target origin ID for default cache behavior"
}

variable "referer_secret" {
  type        = string
  description = "Referer header secret value sent to S3 buckets"
  default     = ""
}
