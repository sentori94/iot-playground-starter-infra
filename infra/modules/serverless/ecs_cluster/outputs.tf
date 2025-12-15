output "cluster_id" {
  description = "ID du cluster ECS"
  value       = aws_ecs_cluster.serverless.id
}

output "cluster_arn" {
  description = "ARN du cluster ECS"
  value       = aws_ecs_cluster.serverless.arn
}

output "cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.serverless.name
}

