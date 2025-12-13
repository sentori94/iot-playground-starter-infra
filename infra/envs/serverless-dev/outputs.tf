# ===========================
# Outputs Serverless
# ===========================

output "api_gateway_url" {
  description = "URL de l'API Gateway pour les Lambda IoT"
  value       = module.api_gateway_lambda_iot.api_endpoint
}

output "lambda_api_custom_domain" {
  description = "Domaine personnalisé pour les Lambda APIs (si configuré)"
  value       = module.api_gateway_lambda_iot.custom_domain_url
}

output "dynamodb_runs_table" {
  description = "Nom de la table DynamoDB Runs"
  value       = module.dynamodb_tables.runs_table_name
}

output "dynamodb_sensor_data_table" {
  description = "Nom de la table DynamoDB SensorData"
  value       = module.dynamodb_tables.sensor_data_table_name
}

output "lambda_run_api_function_name" {
  description = "Nom de la fonction Lambda Run API"
  value       = module.lambda_run_api.function_name
}

output "lambda_sensor_api_function_name" {
  description = "Nom de la fonction Lambda Sensor API"
  value       = module.lambda_sensor_api.function_name
}

