variable "service_name" {
  description = "Nom du service ECS"
  type        = string
}

variable "cluster_id" {
  description = "ID du cluster ECS"
  type        = string
}

variable "image_url" {
  description = "URL de l'image Docker"
  type        = string
}

variable "container_port" {
  description = "Port du container"
  type        = number
}

variable "cpu" {
  description = "CPU pour la task"
  type        = string
  default     = "512"
}

variable "memory" {
  description = "Mémoire pour la task"
  type        = string
  default     = "1024"
}

variable "desired_count" {
  description = "Nombre de tasks désirées"
  type        = number
  default     = 1
}

variable "subnet_ids" {
  description = "Liste des subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du security group"
  type        = string
}

variable "assign_public_ip" {
  description = "Assigner une IP publique"
  type        = bool
  default     = false
}

variable "target_group_arn" {
  description = "ARN du target group (vide si pas d'ALB)"
  type        = string
  default     = ""
}

variable "health_check_grace_period" {
  description = "Période de grâce pour le health check (secondes)"
  type        = number
  default     = 90
}

variable "aws_region" {
  description = "Région AWS"
  type        = string
}

variable "log_retention_days" {
  description = "Rétention des logs CloudWatch (jours)"
  type        = number
  default     = 7
}

variable "environment_variables" {
  description = "Variables d'environnement pour le container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets depuis Secrets Manager"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "secret_arns" {
  description = "Liste des ARNs de secrets autorisés"
  type        = list(string)
  default     = []
}

variable "container_health_check" {
  description = "Configuration du health check du container"
  type = object({
    command     = list(string)
    interval    = number
    timeout     = number
    retries     = number
    startPeriod = number
  })
  default = null
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

