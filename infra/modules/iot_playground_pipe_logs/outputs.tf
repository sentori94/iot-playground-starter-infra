output "subscription_filter_names" {
  description = "Liste des noms des subscription filters créés"
  value       = aws_cloudwatch_log_subscription_filter.run_finished[*].name
}

output "lambda_permission_ids" {
  description = "Liste des IDs des permissions Lambda créées"
  value       = aws_lambda_permission.allow_logs_invoke[*].id
}