variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain name for CloudFront"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for custom domain"
  type        = string
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com)"
  type        = string
  default     = ""
}
