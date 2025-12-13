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

