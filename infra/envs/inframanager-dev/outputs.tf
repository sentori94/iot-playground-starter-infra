output "api_gateway_url" {
  description = "URL de l'API Gateway pour gérer l'infrastructure"
  value       = module.infra_manager.api_gateway_url
}

output "api_gateway_id" {
  description = "ID de l'API Gateway"
  value       = module.infra_manager.api_gateway_id
}

output "deployments_table_name" {
  description = "Nom de la table DynamoDB pour les déploiements"
  value       = module.infra_manager.deployments_table_name
}

output "github_token_secret_name" {
  description = "Nom du secret AWS Secrets Manager pour le token GitHub"
  value       = module.infra_manager.github_token_secret_name
}

output "create_lambda_name" {
  description = "Nom de la Lambda pour créer l'infrastructure"
  value       = module.infra_manager.create_lambda_name
}

output "check_status_lambda_name" {
  description = "Nom de la Lambda pour vérifier le statut"
  value       = module.infra_manager.check_status_lambda_name
}

output "destroy_lambda_name" {
  description = "Nom de la Lambda pour détruire l'infrastructure"
  value       = module.infra_manager.destroy_lambda_name
}

