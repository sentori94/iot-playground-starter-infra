variable "state_bucket_name" {
  type = string
}

variable "db_name" {
  type    = string
  default = "postgres"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}
