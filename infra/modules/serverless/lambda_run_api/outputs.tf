output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.run_api.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.run_api.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.run_api.invoke_arn
}

