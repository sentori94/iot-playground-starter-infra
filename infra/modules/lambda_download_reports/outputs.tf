output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}/download" : "${aws_api_gateway_stage.main.invoke_url}/download"
}

output "api_key_id" {
  description = "API Key ID"
  value       = aws_api_gateway_api_key.reports_api_key.id
}

output "api_key_value" {
  description = "API Key value (sensitive)"
  value       = aws_api_gateway_api_key.reports_api_key.value
  sensitive   = true
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.download_reports.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.download_reports.arn
}

output "api_gateway_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.reports_api.id
}

output "api_key_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the API Key"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "custom_domain_name" {
  description = "Custom domain name for the API (if configured)"
  value       = var.domain_name != "" ? var.domain_name : null
}

output "custom_domain_regional_domain_name" {
  description = "Regional domain name for the custom domain (for Route53 alias)"
  value       = var.domain_name != "" && var.certificate_arn != "" ? aws_api_gateway_domain_name.custom_domain[0].regional_domain_name : null
}
