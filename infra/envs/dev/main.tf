terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "s3" {}  # ← pas de var ici
}

provider "aws" { region = "eu-west-3" }

# VPC & subnets
resource "aws_vpc" "this" {
  cidr_block = "10.30.0.0/16"
  tags = { Name = "iot-vpc-dev" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.30.1.0/24"
  availability_zone = "eu-west-3a"
  tags = { Name = "iot-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.30.2.0/24"
  availability_zone = "eu-west-3b"
  tags = { Name = "iot-subnet-b" }
}

# ECR unique
resource "aws_ecr_repository" "backend" {
  name                 = "iot-backend"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = "iot-playground-starter", Env = "dev" }
}

# SG RDS
resource "aws_security_group" "rds" {
  vpc_id = aws_vpc.this.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "rds-sg" }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags       = { Name = "rds-subnet-group" }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier                 = "iot-sensors-db"
  engine                     = "postgres"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  deletion_protection        = false
  publicly_accessible        = false
  multi_az                   = false
  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  tags = { Project = "iot-playground-starter", Env = "dev" }
}
