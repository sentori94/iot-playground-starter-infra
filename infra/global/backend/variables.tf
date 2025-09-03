variable "region" { type = string, default = "eu-west-3" }
variable "state_bucket_name" { type = string }
variable "lock_table_name" { type = string, default = "terraform-locks" }
variable "tags" { type = map(string), default = { Project = "iot-playground-starter", Owner = "Walid" } }
