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

