variable "name" {
  description = "Nom du service (pour préfixer les security groups)"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "container_port" {
  description = "Port du container"
  type        = number
}

variable "allow_prometheus_scraping" {
  description = "Autoriser le scraping Prometheus depuis n'importe où"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

