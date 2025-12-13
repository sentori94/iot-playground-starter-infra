output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.sensor_api.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.sensor_api.arn
}

output "invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.sensor_api.invoke_arn
}

