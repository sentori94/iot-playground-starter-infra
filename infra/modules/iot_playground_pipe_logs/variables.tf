variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

variable "log_group_name" {
  type = string
}

variable "filter_pattern" {
  type = string
}

variable "lambda_target_arns" {
  type        = list(string)
  description = "Liste des ARNs des Lambdas à déclencher"
}
