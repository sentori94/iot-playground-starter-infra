output "athena_workgroup_name" {
  description = "Nom du workgroup Athena"
  value       = aws_athena_workgroup.grafana.name
}

output "athena_database_name" {
  description = "Nom de la database Athena"
  value       = aws_athena_database.iot_data.name
}

output "athena_results_bucket" {
  description = "Bucket S3 pour les résultats Athena"
  value       = aws_s3_bucket.athena_results.bucket
}

output "grafana_task_role_arn" {
  description = "ARN du rôle IAM pour Grafana (accès Athena+DynamoDB)"
  value       = aws_iam_role.grafana_athena.arn
}

output "create_runs_table_query" {
  description = "Query pour créer la table runs dans Athena"
  value       = aws_athena_named_query.create_runs_table.query
}

output "create_sensor_data_table_query" {
  description = "Query pour créer la table sensor_data dans Athena"
  value       = aws_athena_named_query.create_sensor_data_table.query
}

