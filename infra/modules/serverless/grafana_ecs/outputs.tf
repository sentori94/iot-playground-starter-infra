output "alb_dns_name" {
  description = "DNS name de l'ALB"
  value       = aws_lb.grafana.dns_name
}

output "grafana_url" {
  description = "URL d'accès à Grafana"
  value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : "https://${aws_lb.grafana.dns_name}"
}

output "ecs_service_name" {
  description = "Nom du service ECS Grafana"
  value       = aws_ecs_service.grafana_serverless.name
}

output "alb_security_group_id" {
  description = "ID du security group de l'ALB"
  value       = aws_security_group.alb.id
}

output "grafana_security_group_id" {
  description = "ID du security group de Grafana"
  value       = aws_security_group.grafana.id
}

