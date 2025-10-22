output "alb_security_group_id" {
  description = "ID du security group de l'ALB"
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "ID du security group du service ECS"
  value       = aws_security_group.ecs_service.id
}

