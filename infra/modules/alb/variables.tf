variable "name" {
  description = "Nom de l'ALB"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Liste des subnet IDs pour l'ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID du security group de l'ALB"
  type        = string
}

variable "internal" {
  description = "ALB interne ou externe"
  type        = bool
  default     = false
}

variable "target_port" {
  description = "Port cible du target group"
  type        = number
}

variable "listener_port" {
  description = "Port du listener"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin du health check"
  type        = string
  default     = "/"
}

variable "health_check_interval" {
  description = "Intervalle du health check (secondes)"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Timeout du health check (secondes)"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Seuil healthy"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Seuil unhealthy"
  type        = number
  default     = 3
}

variable "health_check_matcher" {
  description = "Matcher HTTP pour health check"
  type        = string
  default     = "200-399"
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

