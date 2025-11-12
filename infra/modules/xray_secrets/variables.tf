variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "xray_access_key_id" {
  description = "AWS X-Ray Access Key ID"
  type        = string
  sensitive   = true
}

variable "xray_secret_access_key" {
  description = "AWS X-Ray Secret Access Key"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

