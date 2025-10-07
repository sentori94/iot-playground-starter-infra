output "alb_dns_name" { value = aws_lb.app.dns_name }
output "vpc_id"       { value = local.vpc_id }

output "spring_alb_dns" {
  value = aws_lb.app.dns_name
}

output "prometheus_alb_dns" {
  value = aws_lb.prometheus.dns_name
}

output "grafana_alb_dns" {
  value = aws_lb.grafana.dns_name
}