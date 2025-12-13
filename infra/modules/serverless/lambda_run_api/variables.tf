variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "runs_table_name" {
  description = "Name of the Runs DynamoDB table"
  type        = string
}

variable "runs_table_arn" {
  description = "ARN of the Runs DynamoDB table"
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

