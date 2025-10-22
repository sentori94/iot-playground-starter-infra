variable "name" {
  description = "Nom du bastion"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet (public)"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Nom de la clé SSH"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "Liste des CIDR autorisés à se connecter en SSH"
  type        = list(string)
}

variable "eip_allocation_id" {
  description = "ID d'allocation de l'EIP (optionnel)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags communs"
  type        = map(string)
  default     = {}
}

