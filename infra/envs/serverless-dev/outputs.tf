# ===========================
# Outputs Serverless
# ===========================

output "api_gateway_url" {
  description = "URL de l'API Gateway pour les Lambda IoT"
  value       = module.api_gateway_lambda_iot.api_endpoint
}

output "lambda_api_custom_domain" {
  description = "Domaine personnalisé pour les Lambda APIs"
  value       = module.api_gateway_lambda_iot.custom_domain_url != "" ? module.api_gateway_lambda_iot.custom_domain_url : "Custom domain non configuré - utilisez api_gateway_url"
}

output "lambda_api_certificate_arn" {
  description = "ARN du certificat ACM pour les Lambda APIs"
  value       = length(module.acm_lambda_api) > 0 ? module.acm_lambda_api[0].certificate_validated_arn : "Pas de certificat"
}

output "lambda_api_custom_domain_configured" {
  description = "Le domaine personnalisé est-il configuré ?"
  value       = module.api_gateway_lambda_iot.custom_domain_configured
}

output "lambda_api_regional_domain" {
  description = "Nom de domaine régional pour le domaine personnalisé"
  value       = module.api_gateway_lambda_iot.custom_domain_regional_name
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

# ===========================
# Outputs Grafana (si activé)
# ===========================

output "grafana_alb_url" {
  description = "URL de l'ALB Grafana"
  value       = var.enable_grafana && length(module.grafana_serverless) > 0 ? module.grafana_serverless[0].alb_dns_name : "Grafana non déployé"
}

output "grafana_url" {
  description = "URL complète de Grafana"
  value       = var.enable_grafana && length(module.grafana_serverless) > 0 ? "http://${module.grafana_serverless[0].alb_dns_name}" : "Grafana non déployé"
}

output "grafana_custom_domain" {
  description = "Domaine personnalisé Grafana (si configuré)"
  value       = var.grafana_domain_name != "" ? var.grafana_domain_name : "Pas de domaine personnalisé configuré"
}


