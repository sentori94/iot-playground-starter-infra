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

output "athena_workgroup_name" {
  description = "Nom du workgroup Athena"
  value       = module.athena_dynamodb.athena_workgroup_name
}

output "athena_database_name" {
  description = "Nom de la database Athena"
  value       = module.athena_dynamodb.athena_database_name
}

output "athena_results_bucket" {
  description = "Bucket S3 pour les résultats Athena"
  value       = module.athena_dynamodb.athena_results_bucket
}

