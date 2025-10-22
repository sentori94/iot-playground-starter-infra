output "alb_arn" {
  description = "ARN de l'ALB"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name de l'ALB"
  value       = aws_lb.this.dns_name
}

output "target_group_arn" {
  description = "ARN du target group"
  value       = aws_lb_target_group.this.arn
}

output "listener_arn" {
  description = "ARN du listener"
  value       = aws_lb_listener.http.arn
}

