variable "cluster_name" {
  description = "Nom du cluster ECS"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

