# ===========================
# RDS PostgreSQL Module
# ===========================

resource "random_password" "db" {
  length           = 24
  special          = true
  # Ne pas inclure '/', '"', '@', ' '
  override_special = "!#$%^&*()-_=+[]{}:,.?"
}

# Security Group pour RDS
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg-${var.environment}"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      description     = "PostgreSQL from ${ingress.value}"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project}-rds-sg-${var.environment}"
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project}-rds-subnet-group-${var.environment}"
  subnet_ids = var.subnet_ids
  tags = merge(var.tags, {
    Name = "${var.project}-rds-subnet-group-${var.environment}"
  })
}

resource "aws_db_instance" "postgres" {
  identifier                 = "${var.project}-db-${var.environment}"
  engine                     = "postgres"
  instance_class             = var.instance_class
  allocated_storage          = var.allocated_storage
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = random_password.db.result
  skip_final_snapshot        = var.skip_final_snapshot
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  deletion_protection        = var.deletion_protection
  publicly_accessible        = var.publicly_accessible
  multi_az                   = var.multi_az
  backup_retention_period    = var.backup_retention_period
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  tags                       = var.tags
}

# Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name = "${var.project}-rds-credentials-${var.environment}"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = var.db_name
    engine   = "postgres"
    url      = "jdbc:postgresql://${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}"
  })
}
