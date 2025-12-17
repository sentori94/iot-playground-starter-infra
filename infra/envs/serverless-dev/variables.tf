variable "project" {
  description = "Nom du projet"
  type        = string
  default     = "iot-playground"
}

variable "env" {
  description = "Environnement (serverless-dev, serverless-staging, serverless-prod)"
  type        = string
  default     = "serverless-dev"
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3"
}

variable "route53_zone_name" {
  description = "Nom de la zone Route53 hébergée (ex: sentori-studio.com)"
  type        = string
  default     = ""
}

variable "lambda_api_domain_name" {
  description = "Nom de domaine pour les Lambda API (ex: api-lambda-iot.sentori-studio.com)"
  type        = string
  default     = ""
}

variable "grafana_url" {
  description = "Base URL de Grafana pour la génération des liens (ex: http://grafana.example.com)"
  type        = string
  default     = "http://localhost:3000"
}

variable "grafana_domain_name" {
  description = "Nom de domaine pour Grafana (ex: grafana-lambda-iot.sentori-studio.com)"
  type        = string
  default     = ""
}

# ===========================
# Variables Grafana ECS
# ===========================


variable "vpc_cidr" {
  description = "CIDR block pour le VPC Serverless (Grafana)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "Liste des Availability Zones pour le VPC"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "grafana_image_uri" {
  description = "URI de l'image Docker Grafana dans ECR"
  type        = string
  default     = ""
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


