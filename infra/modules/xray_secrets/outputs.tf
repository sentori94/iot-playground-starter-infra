output "secret_arn" {
  description = "ARN of the X-Ray credentials secret"
  value       = aws_secretsmanager_secret.xray_credentials.arn
}

output "secret_id" {
  description = "ID of the X-Ray credentials secret"
  value       = aws_secretsmanager_secret.xray_credentials.id
}

