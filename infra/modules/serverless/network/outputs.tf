output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs des NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID de la route table publique"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs des route tables privées"
  value       = aws_route_table.private[*].id
}

