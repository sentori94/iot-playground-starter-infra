output "zone_id" {
  description = "ID de la zone Route53"
  value       = data.aws_route53_zone.main.zone_id
}

output "zone_name" {
  description = "Nom de la zone Route53"
  value       = data.aws_route53_zone.main.name
}

output "name_servers" {
  description = "Name servers de la zone Route53"
  value       = data.aws_route53_zone.main.name_servers
}

output "record_fqdns" {
  description = "FQDNs des enregistrements créés"
  value       = { for k, v in aws_route53_record.alb_records : k => v.fqdn }
}
