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
  value       = "http://${module.spring_app_alb.alb_dns_name}"
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
