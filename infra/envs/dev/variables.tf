variable "state_bucket_name" {
  type = string
}

variable "db_name" {
  type    = string
  default = "postgres"
}

variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "cluster_name" {
  type    = string
  default = "iot-playground"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "project" {
  default = "iot-playground"
}

variable "env" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "my_ip" {
  default = "90.7.211.200/32"
}

variable "ssh_key_name" {
  default = "rds_bastion_ssh_key"
}

variable "s3_bucket_name" {
  default = "iot-background-starter-files-bucket"
}

variable "route53_zone_name" {
  description = "Nom de la zone Route53 hébergée (ex: example.com)"
  type        = string
  default     = ""
}

variable "backend_domain_name" {
  description = "Nom de domaine pour l'API backend (ex: api.example.com)"
  type        = string
  default     = ""
}

variable "prometheus_domain_name" {
  description = "Nom de domaine pour Prometheus (ex: prometheus.example.com)"
  type        = string
  default     = ""
}

variable "grafana_domain_name" {
  description = "Nom de domaine pour Grafana (ex: grafana.example.com)"
  type        = string
  default     = ""
}

variable "api_reports_domain_name" {
  description = "Nom de domaine pour l'API de téléchargement des rapports (ex: api-reports.example.com)"
  type        = string
  default     = ""
}

variable "frontend_url" {
  description = "URL complète du frontend pour CORS (ex: https://app.sentori-studio.com)"
  type        = string
  default     = "https://app-iot.sentori-studio.com,http://app-iot.sentori-studio.com"
}

variable "prometheus_repo" {
  default = "prometheus"
}

variable "grafana_repo" {
  default = "grafana"
}

variable "aws_account_id" {
  default = "908518190934"
}

variable "app_name" { default = "spring-app" }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "image_url" { default = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-starter:latest" } # ex : <acct>.908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-backend:latest
variable "container_port" { default = 8080 }
variable "desired_count" { default = 1 }
variable "health_path" { default = "/actuator/health" }

# Variables pour les images ECR
variable "grafana_image_ecr" {
  description = "URL de l'image Grafana dans ECR"
  type        = string
}

variable "prom_image_ecr" {
  description = "URL de l'image Prometheus dans ECR"
  type        = string
}

# Variables pour ECS
variable "ecs_cpu" {
  description = "CPU pour les tâches ECS"
  type        = string
  default     = "512"
}

variable "ecs_memory" {
  description = "Mémoire pour les tâches ECS"
  type        = string
  default     = "1024"
}

# Variables pour RDS
variable "rds_instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "bastion_key_name" {
  description = "Nom de la clé SSH pour le bastion"
  type        = string
  default     = "manually_generated_key_bastion"
}

# Variables pour AWS X-Ray
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
