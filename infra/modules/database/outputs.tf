output "db_instance_endpoint" {
  description = "Endpoint de la base de données"
  value       = aws_db_instance.postgres.endpoint
}

output "db_instance_address" {
  description = "Adresse de la base de données"
  value       = aws_db_instance.postgres.address
}

output "db_instance_port" {
  description = "Port de la base de données"
  value       = aws_db_instance.postgres.port
}

output "db_security_group_id" {
  description = "ID du security group RDS"
  value       = aws_security_group.rds.id
}

output "secret_arn" {
  description = "ARN du secret dans Secrets Manager"
  value       = aws_secretsmanager_secret.db.arn
}

output "db_name" {
  description = "Nom de la base de données"
  value       = var.db_name
}

