variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Name prefix for resources"
  default     = "static-site-cicd"
}

variable "github_org" {
  type        = string
  description = "GitHub Organization or Username"
  default     = "raghavendra2006"
}

variable "github_repo" {
  type        = string
  description = "GitHub Repository Name"
  default     = "STATIC-WEBSITE-USING-CI-CD"
}
