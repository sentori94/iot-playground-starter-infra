# ===========================
# Outputs
# ===========================

output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "spring_app_alb_dns" {
  description = "DNS de l'ALB pour l'application Spring"
  value       = module.spring_app_alb.alb_dns_name
}

output "spring_app_url" {
  description = "URL de l'application Spring"
  value       = var.backend_domain_name != "" ? "https://${var.backend_domain_name}" : "http://${module.spring_app_alb.alb_dns_name}"
}

output "spring_app_custom_domain" {
  description = "Domaine personnalisé Route53 pour l'application Spring (si configuré)"
  value       = var.backend_domain_name != "" ? var.backend_domain_name : null
}

output "prometheus_alb_dns" {
  description = "DNS de l'ALB pour Prometheus"
  value       = module.prometheus_alb.alb_dns_name
}

output "prometheus_url" {
  description = "URL de Prometheus"
  value       = "http://${module.prometheus_alb.alb_dns_name}"
}

output "grafana_alb_dns" {
  description = "DNS de l'ALB pour Grafana"
  value       = module.grafana_alb.alb_dns_name
}

output "grafana_url" {
  description = "URL de Grafana"
  value       = "http://${module.grafana_alb.alb_dns_name}"
}

output "rds_endpoint" {
  description = "Endpoint de la base de données RDS"
  value       = module.database.db_instance_endpoint
}

output "bastion_public_ip" {
  description = "IP publique du bastion"
  value       = module.bastion.public_ip
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = module.ecs_cluster.cluster_name
}

# ===========================
# API Gateway Downloads Reports
# ===========================

output "reports_api_endpoint" {
  description = "Endpoint de l'API pour télécharger les rapports"
  value       = module.lambda_download_reports.api_endpoint
}

output "reports_api_key" {
  description = "API Key pour accéder à l'API de téléchargement (SENSIBLE - à stocker en sécurité)"
  value       = module.lambda_download_reports.api_key_value
  sensitive   = true
}

output "reports_api_usage_instructions" {
  description = "Instructions pour utiliser l'API"
  value       = "Utilisez: curl -H 'x-api-key: <API_KEY>' ${module.lambda_download_reports.api_endpoint}"
}

