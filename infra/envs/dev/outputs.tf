output "alb_dns_name" { value = aws_lb.app.dns_name }
output "vpc_id"       { value = local.vpc_id }