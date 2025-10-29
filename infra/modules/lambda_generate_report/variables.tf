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

variable "vpc_id" {
  type        = string
  description = "VPC ID pour la Lambda"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Liste des subnet IDs pour la Lambda (privés)"
}

variable "db_security_group_id" {
  type        = string
  description = "Security group ID de la base de données"
}
