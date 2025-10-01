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

variable "aws_region" {
  type    = string
  default = "eu-west-3"
}

variable "cluster_name" {
  type    = string
  default = "iot-playground-starter"
}

variable "eks_version" {
  type    = string
  default = "1.30"
}

variable "project" {
  default = "iot-playground-starter"
}


variable "my_ip" {
  default = "90.7.211.200/32"
}

variable "ssh_key_name" {
  default = "rds_bastion_ssh_key"
}

variable "s3_bucket_name" {
  default = "iot-background-starter-files-bucket"
}

variable "prometheus_repo" {
  default = "prometheus"
}

variable "aws_account_id" {
  default = "908518190934"
}

variable "app_name" { default = "spring-app" }
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }
variable "image_url" { default = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-starter:latest" } # ex : <acct>.908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-backend:latest
variable "container_port" { default = 8080 }
variable "desired_count" { default = 1 }
variable "health_path" { default = "/actuator/health" }