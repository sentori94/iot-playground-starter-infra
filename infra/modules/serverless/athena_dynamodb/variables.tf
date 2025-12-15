variable "project" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement"
  type        = string
}

variable "runs_table_name" {
  description = "Nom de la table DynamoDB Runs"
  type        = string
}

variable "runs_table_arn" {
  description = "ARN de la table DynamoDB Runs"
  type        = string
}

variable "sensor_data_table_name" {
  description = "Nom de la table DynamoDB SensorData"
  type        = string
}

variable "sensor_data_table_arn" {
  description = "ARN de la table DynamoDB SensorData"
  type        = string
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

