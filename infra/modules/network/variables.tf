variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Liste des CIDR pour les subnets publics"
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Liste des CIDR pour les subnets privés"
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24"]
}

variable "availability_zones" {
  description = "Liste des zones de disponibilité (suffixes)"
  type        = list(string)
  default     = ["a", "b"]
}

variable "tags" {
  description = "Tags communs à toutes les ressources"
  type        = map(string)
  default     = {}
}

