variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Optional custom domain name for CloudFront"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "Optional ACM certificate ARN for custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}

variable "route53_zone_name" {
  description = "Route53 hosted zone name (e.g., example.com) - required if domain_name is set"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
