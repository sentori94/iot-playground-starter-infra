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
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_endpoints" {
  description = "All API endpoints"
  value = {
    create_infra         = "${aws_apigatewayv2_stage.default.invoke_url}/infra/create"
    destroy_infra        = "${aws_apigatewayv2_stage.default.invoke_url}/infra/destroy"
    check_status         = "${aws_apigatewayv2_stage.default.invoke_url}/infra/status/{deploymentId}"
    latest_deployment    = "${aws_apigatewayv2_stage.default.invoke_url}/infra/latest-deployment"
    list_deployments     = "${aws_apigatewayv2_stage.default.invoke_url}/infra/list-deployments"
    cancel_deployment    = "${aws_apigatewayv2_stage.default.invoke_url}/infra/cancel-deployment"
  }
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
