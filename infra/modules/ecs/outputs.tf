output "cluster_id" {
  description = "ID du cluster ECS"
  value       = aws_ecs_cluster.this.id
}

output "cluster_name" {
  description = "Nom du cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "cluster_arn" {
  description = "ARN du cluster ECS"
  value       = aws_ecs_cluster.this.arn
}
