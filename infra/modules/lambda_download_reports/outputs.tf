output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.main.invoke_url}/download"
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
