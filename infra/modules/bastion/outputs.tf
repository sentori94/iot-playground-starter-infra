output "instance_id" {
  description = "ID de l'instance bastion"
  value       = aws_instance.bastion.id
}

output "public_ip" {
  description = "IP publique du bastion"
  value       = aws_instance.bastion.public_ip
}

output "security_group_id" {
  description = "ID du security group du bastion"
  value       = aws_security_group.bastion.id
}

