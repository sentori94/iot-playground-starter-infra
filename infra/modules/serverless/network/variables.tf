variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC existant"
  type        = string
}

variable "availability_zones" {
  description = "Liste des AZs à utiliser"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "public_subnet_cidr_base" {
  description = "CIDR de base pour les subnets publics (sera subdivisé)"
  type        = string
  default     = "10.0.100.0/24"
}

variable "private_subnet_cidr_base" {
  description = "CIDR de base pour les subnets privés (sera subdivisé)"
  type        = string
  default     = "10.0.200.0/24"
}

variable "create_internet_gateway" {
  description = "Créer un Internet Gateway (mettre false si déjà existant dans le VPC)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

