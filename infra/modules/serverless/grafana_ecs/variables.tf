variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs des subnets publics pour l'ALB"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs des subnets privés pour Grafana"
  type        = list(string)
}

variable "ecs_cluster_id" {
  description = "ID du cluster ECS"
  type        = string
}

variable "grafana_image_uri" {
  description = "URI de l'image Docker Grafana dans ECR"
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

variable "custom_domain_name" {
  description = "Nom de domaine personnalisé (ex: grafana-lambda-iot.sentori-studio.com)"
  type        = string
}

variable "certificate_arn" {
  description = "ARN du certificat ACM pour HTTPS"
  type        = string
}

variable "route53_zone_id" {
  description = "ID de la zone Route53"
  type        = string
}

variable "grafana_task_role_arn" {
  description = "ARN du rôle IAM pour la tâche Grafana (accès Athena+DynamoDB)"
  type        = string
}

variable "athena_workgroup_name" {
  description = "Nom du workgroup Athena"
  type        = string
}

variable "athena_database_name" {
  description = "Nom de la database Athena"
  type        = string
}

variable "task_cpu" {
  description = "CPU pour la tâche ECS (256, 512, 1024, 2048, 4096)"
  type        = string
  default     = "512"
}

variable "task_memory" {
  description = "Mémoire pour la tâche ECS (512, 1024, 2048, etc.)"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Nombre de tâches Grafana à exécuter"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

