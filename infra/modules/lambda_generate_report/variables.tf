variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "reports_bucket" {
  type = string
}

variable "db_secret_arn" {
  type        = string
  description = "ARN du secret contenant les credentials DB"
}
