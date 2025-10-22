output "service_id" {
  description = "ID du service ECS"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Nom du service ECS"
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN de la task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "execution_role_arn" {
  description = "ARN du rôle d'exécution"
  value       = aws_iam_role.exec.arn
}

output "task_role_arn" {
  description = "ARN du rôle de task"
  value       = aws_iam_role.task.arn
}

