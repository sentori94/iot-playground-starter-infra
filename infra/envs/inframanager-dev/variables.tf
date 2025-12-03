variable "state_bucket_name" {
  description = "Nom du bucket S3 pour le state Terraform"
  type        = string
}

variable "github_repo_owner" {
  description = "Propriétaire du repository GitHub (username ou organisation)"
  type        = string
}

variable "project" {
  description = "Nom du projet"
  type        = string
  default     = "iot-playground"
}

variable "environment" {
  description = "Environnement"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "github_repo_name" {
  description = "Nom du repository GitHub"
  type        = string
  default     = "iot-playground-starter-infra"
}
