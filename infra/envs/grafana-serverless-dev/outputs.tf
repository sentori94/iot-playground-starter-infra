output "grafana_url" {
  description = "URL d'accès à Grafana"
  value       = module.grafana_serverless.grafana_url
}

output "vpc_id" {
  description = "ID du VPC Grafana"
  value       = module.vpc_serverless.vpc_id
}

output "ecs_cluster_name" {
  description = "Nom du cluster ECS"
  value       = module.ecs_cluster_serverless.cluster_name
}

output "cloudwatch_role_arn" {
  description = "ARN du rôle IAM CloudWatch pour Grafana"
  value       = aws_iam_role.grafana_cloudwatch.arn
}

