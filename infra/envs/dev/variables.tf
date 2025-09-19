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

variable "aws_region" {
    type = string
    default = "eu-west-3"
}

variable "cluster_name"  {
    type = string
    default = "iot-playground-starter"
}

variable "eks_version" {
    type = string
    default = "1.30"
}