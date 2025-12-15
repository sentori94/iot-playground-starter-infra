output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.serverless.id
}

output "vpc_cidr" {
  description = "CIDR du VPC"
  value       = aws_vpc.serverless.cidr_block
}

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

output "internet_gateway_id" {
  description = "ID de l'Internet Gateway"
  value       = aws_internet_gateway.main.id
}

