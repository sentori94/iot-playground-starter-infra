variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "terraform_state_dynamodb_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
  default     = "terraform-locks"
}

variable "vpc_id" {
  description = "VPC ID where Lambda will run"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs for Lambda"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for Lambda"
  type        = list(string)
  default     = []
}

variable "github_repo_owner" {
  description = "GitHub repository owner (ex: sentori-studio)"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name (ex: iot-playground-starter-infra)"
  type        = string
}

# Variables for auto-destroy idle infrastructure
variable "enable_auto_destroy" {
  description = "Enable automatic infrastructure destruction on idle"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address for auto-destroy notifications"
  type        = string
  default     = ""
}

variable "auto_destroy_cloudwatch_log_group" {
  description = "CloudWatch log group to monitor for activity"
  type        = string
  default     = ""
}

variable "auto_destroy_log_filter_pattern" {
  description = "Pattern to search in logs (e.g., 'finished SUCCESS')"
  type        = string
  default     = "finished SUCCESS"
}

variable "auto_destroy_idle_threshold_hours" {
  description = "Number of hours of inactivity before triggering destroy"
  type        = number
  default     = 2
}

variable "auto_destroy_check_schedule" {
  description = "EventBridge schedule expression for auto-destroy checks"
  type        = string
  default     = "rate(1 hour)"
}

variable "domain_name" {
  description = "Custom domain name for API Gateway (ex: infra-manager.example.com)"
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
