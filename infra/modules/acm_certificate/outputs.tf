output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = aws_acm_certificate.cert.arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.cert.domain_name
}

output "certificate_validation_status" {
  description = "Validation status of the certificate"
  value       = aws_acm_certificate_validation.cert.id
}

output "certificate_validated_arn" {
  description = "ARN of the validated certificate (use this for dependencies)"
  value       = aws_acm_certificate_validation.cert.certificate_arn
}
