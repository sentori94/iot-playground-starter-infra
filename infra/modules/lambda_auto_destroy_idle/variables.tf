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

variable "github_token_secret_arn" {
  description = "ARN of the GitHub token secret in Secrets Manager"
  type        = string
}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "notification_email" {
  description = "Email address for notifications"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "CloudWatch log group to monitor for activity"
  type        = string
  default     = ""
}

variable "log_filter_pattern" {
  description = "Pattern to search in logs (e.g., 'finished SUCCESS')"
  type        = string
  default     = "finished SUCCESS"
}

variable "idle_threshold_hours" {
  description = "Number of hours of inactivity before triggering destroy"
  type        = number
  default     = 2
}

variable "check_schedule" {
  description = "EventBridge schedule expression (default: every hour)"
  type        = string
  default     = "rate(6 hours)"
}

variable "subnet_ids" {
  description = "List of subnet IDs for Lambda VPC configuration"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for Lambda VPC configuration"
  type        = list(string)
  default     = []
}
