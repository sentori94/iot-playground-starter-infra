variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "reports_bucket" {
  description = "S3 bucket name containing reports"
  type        = string
}

variable "api_throttle_rate_limit" {
  description = "API Gateway rate limit (requests per second)"
  type        = number
  default     = 2
}

variable "api_throttle_burst_limit" {
  description = "API Gateway burst limit"
  type        = number
  default     = 5
}

variable "domain_name" {
  description = "Custom domain name for API Gateway (ex: api-reports.example.com)"
  type        = string
  default     = ""
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for the domain"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ARN of ACM certificate for the custom domain (must be in the same region)"
  type        = string
  default     = ""
}
