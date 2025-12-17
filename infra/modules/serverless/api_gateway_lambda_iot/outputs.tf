output "api_id" {
  description = "ID of the API Gateway"
  value       = aws_api_gateway_rest_api.lambda_iot.id
}

output "api_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.lambda_iot.execution_arn
}

output "api_endpoint" {
  description = "Invoke URL of the API Gateway"
  value       = aws_api_gateway_stage.lambda_iot.invoke_url
}

output "custom_domain_url" {
  description = "Custom domain URL (if configured)"
  value       = var.custom_domain_name != "" ? "https://${var.custom_domain_name}" : ""
}

output "custom_domain_regional_name" {
  description = "Regional domain name for custom domain"
  value       = var.custom_domain_name != "" && length(aws_api_gateway_domain_name.lambda_iot) > 0 ? aws_api_gateway_domain_name.lambda_iot[0].regional_domain_name : ""
}

output "custom_domain_configured" {
  description = "Is custom domain configured"
  value       = var.custom_domain_name != "" && var.certificate_arn != "" && var.route53_zone_id != ""
}

