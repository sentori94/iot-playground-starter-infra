data "aws_ssm_parameter" "db_password" { name = var.db_password_ssm_param }

resource "aws_db_subnet_group" "this" {
  name       = "iotp-dev-rds-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier                 = var.db_identifier
  engine                     = "postgres"
  engine_version             = "16"
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = data.aws_ssm_parameter.db_password.value
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = var.vpc_security_group_ids
  publicly_accessible        = false
  deletion_protection        = true
  skip_final_snapshot        = false
  backup_retention_period    = 7
  auto_minor_version_upgrade = true
  tags = { Project = "iot-playground-starter", Env = "dev" }
}
