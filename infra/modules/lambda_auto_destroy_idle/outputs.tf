output "lambda_function_arn" {
  description = "ARN of the auto-destroy Lambda function"
  value       = aws_lambda_function.auto_destroy_idle.arn
}

output "lambda_function_name" {
  description = "Name of the auto-destroy Lambda function"
  value       = aws_lambda_function.auto_destroy_idle.function_name
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.check_idle.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda logs"
  value       = aws_cloudwatch_log_group.auto_destroy_logs.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications"
  value       = aws_sns_topic.notifications.arn
}
