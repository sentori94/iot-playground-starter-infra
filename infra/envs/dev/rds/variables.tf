variable "db_identifier"           { type = string, default = "iot-sensors-db" }
variable "db_name"                 { type = string, default = "postgres" }
variable "db_username"             { type = string }
variable "db_password_ssm_param"   { type = string, default = "/iot/dev/db/password" }
variable "subnet_ids"              { type = list(string) }
variable "vpc_security_group_ids"  { type = list(string) }
