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

output "get_latest_deployment_lambda_arn" {
  description = "ARN of the get latest deployment Lambda"
  value       = aws_lambda_function.get_latest_deployment.arn
}

output "get_latest_deployment_lambda_name" {
  description = "Name of the get latest deployment Lambda"
  value       = aws_lambda_function.get_latest_deployment.function_name
}

output "list_deployments_lambda_arn" {
  description = "ARN of the list deployments Lambda"
  value       = aws_lambda_function.list_deployments.arn
}

output "list_deployments_lambda_name" {
  description = "Name of the list deployments Lambda"
  value       = aws_lambda_function.list_deployments.function_name
}

output "cancel_deployment_lambda_arn" {
  description = "ARN of the cancel deployment Lambda"
  value       = aws_lambda_function.cancel_deployment.arn
}

output "cancel_deployment_lambda_name" {
  description = "Name of the cancel deployment Lambda"
  value       = aws_lambda_function.cancel_deployment.function_name
}

output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : aws_apigatewayv2_stage.default.invoke_url
}

output "api_endpoints" {
  description = "All API endpoints"
  value = {
    create_infra         = var.domain_name != "" ? "https://${var.domain_name}/infra/create" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/create"
    destroy_infra        = var.domain_name != "" ? "https://${var.domain_name}/infra/destroy" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/destroy"
    check_status         = var.domain_name != "" ? "https://${var.domain_name}/infra/status/{deploymentId}" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/status/{deploymentId}"
    latest_deployment    = var.domain_name != "" ? "https://${var.domain_name}/infra/latest-deployment" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/latest-deployment"
    list_deployments     = var.domain_name != "" ? "https://${var.domain_name}/infra/list-deployments" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/list-deployments"
    cancel_deployment    = var.domain_name != "" ? "https://${var.domain_name}/infra/cancel-deployment" : "${aws_apigatewayv2_stage.default.invoke_url}/infra/cancel-deployment"
  }
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.infra_manager.id
}

output "custom_domain_name" {
  description = "Custom domain name for the API (if configured)"
  value       = var.domain_name != "" ? var.domain_name : null
}

output "custom_domain_target" {
  description = "Target domain name for the custom domain (for Route53 alias)"
  value       = var.domain_name != "" && var.certificate_arn != "" ? aws_apigatewayv2_domain_name.custom_domain[0].domain_name_configuration[0].target_domain_name : null
}

output "deployments_table_name" {
  description = "DynamoDB table name for deployments"
  value       = aws_dynamodb_table.deployments.name
}

output "github_token_secret_name" {
  description = "AWS Secrets Manager secret name for GitHub token"
  value       = aws_secretsmanager_secret.github_token.name
}

output "github_token_secret_arn" {
  description = "AWS Secrets Manager secret ARN for GitHub token"
  value       = aws_secretsmanager_secret.github_token.arn
}

# Auto-Destroy outputs
output "auto_destroy_lambda_arn" {
  description = "ARN of the auto-destroy Lambda function"
  value       = var.enable_auto_destroy ? module.auto_destroy_idle[0].lambda_function_arn : null
}

output "auto_destroy_lambda_name" {
  description = "Name of the auto-destroy Lambda function"
  value       = var.enable_auto_destroy ? module.auto_destroy_idle[0].lambda_function_name : null
}

output "auto_destroy_sns_topic_arn" {
  description = "ARN of the SNS topic for auto-destroy notifications"
  value       = var.enable_auto_destroy ? module.auto_destroy_idle[0].sns_topic_arn : null
}
