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

variable "subnet_ids" {
  description = "IDs des subnets pour RDS"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "Liste des security groups autorisés à se connecter à RDS"
  type        = list(string)
}

variable "instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Espace de stockage alloué (GB)"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Nom de la base de données"
  type        = string
  default     = "postgres"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot lors de la suppression"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protection contre la suppression"
  type        = bool
  default     = false
}

variable "publicly_accessible" {
  description = "La base est-elle publiquement accessible"
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Déploiement multi-AZ"
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Période de rétention des backups (jours)"
  type        = number
  default     = 7
}

variable "auto_minor_version_upgrade" {
  description = "Mise à jour automatique des versions mineures"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}
