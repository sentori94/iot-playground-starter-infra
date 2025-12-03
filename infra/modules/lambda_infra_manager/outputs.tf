output "create_lambda_arn" {
  description = "ARN of the create infrastructure Lambda"
  value       = aws_lambda_function.create_infra.arn
}

output "create_lambda_name" {
  description = "Name of the create infrastructure Lambda"
  value       = aws_lambda_function.create_infra.function_name
}

output "check_status_lambda_arn" {
  description = "ARN of the check status Lambda"
  value       = aws_lambda_function.check_status.arn
}

output "check_status_lambda_name" {
  description = "Name of the check status Lambda"
  value       = aws_lambda_function.check_status.function_name
}

output "destroy_lambda_arn" {
  description = "ARN of the destroy infrastructure Lambda"
  value       = aws_lambda_function.destroy_infra.arn
}

output "destroy_lambda_name" {
  description = "Name of the destroy infrastructure Lambda"
  value       = aws_lambda_function.destroy_infra.function_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.infra_manager.id
}

output "deployments_table_name" {
  description = "DynamoDB table name for deployments"
  value       = aws_dynamodb_table.deployments.name
}

output "github_token_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub token"
  value       = aws_secretsmanager_secret.github_token.name
}
