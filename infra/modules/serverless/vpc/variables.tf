variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "Liste des AZs"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

