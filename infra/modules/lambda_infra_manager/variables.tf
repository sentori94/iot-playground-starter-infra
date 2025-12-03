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

