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

