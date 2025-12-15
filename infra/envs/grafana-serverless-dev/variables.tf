variable "project" {
  description = "Nom du projet"
  type        = string
  default     = "iot-playground"
}

variable "env" {
  description = "Environnement"
  type        = string
  default     = "grafana-serverless-dev"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "route53_zone_name" {
  description = "Nom de la zone Route53"
  type        = string
  default     = ""
}

variable "grafana_domain_name" {
  description = "Nom de domaine pour Grafana"
  type        = string
  default     = ""
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

variable "grafana_image_uri" {
  description = "URI de l'image Docker Grafana"
  type        = string
}

variable "grafana_image_tag" {
  description = "Tag de l'image Grafana"
  type        = string
  default     = "latest"
}

variable "grafana_admin_password" {
  description = "Mot de passe admin Grafana"
  type        = string
  sensitive   = true
}

