# ===========================
# Configuration Terraform Serverless
# ===========================

locals {
  common_tags = {
    Project      = var.project
    Environment  = var.env
    ManagedBy    = "Terraform"
    Architecture = "Serverless"
  }
}


# ===========================
# Module DynamoDB Tables
# ===========================
module "dynamodb_tables" {
  source = "../../modules/serverless/dynamodb_tables"

  project     = var.project
  environment = var.env
  tags        = local.common_tags
}

# ===========================
# Module API Gateway Lambda IoT
# ===========================
module "api_gateway_lambda_iot" {
  source = "../../modules/serverless/api_gateway_lambda_iot"

  project                       = var.project
  environment                   = var.env
  lambda_run_api_invoke_arn     = module.lambda_run_api.invoke_arn
  lambda_sensor_api_invoke_arn  = module.lambda_sensor_api.invoke_arn
  custom_domain_name            = ""  # Pas de domaine personnalisé pour le moment
  certificate_arn               = ""
  route53_zone_id               = ""
  tags                          = local.common_tags
}

# ===========================
# Module Lambda Run API
# ===========================
module "lambda_run_api" {
  source = "../../modules/serverless/lambda_run_api"

  project                   = var.project
  environment               = var.env
  runs_table_name           = module.dynamodb_tables.runs_table_name
  runs_table_arn            = module.dynamodb_tables.runs_table_arn
  api_gateway_execution_arn = module.api_gateway_lambda_iot.api_execution_arn
  grafana_url               = var.grafana_url
  tags                      = local.common_tags
}

# ===========================
# Module Lambda Sensor API
# ===========================
module "lambda_sensor_api" {
  source = "../../modules/serverless/lambda_sensor_api"

  project                   = var.project
  environment               = var.env
  sensor_data_table_name    = module.dynamodb_tables.sensor_data_table_name
  sensor_data_table_arn     = module.dynamodb_tables.sensor_data_table_arn
  api_gateway_execution_arn = module.api_gateway_lambda_iot.api_execution_arn
  tags                      = local.common_tags
}



# ===========================
# Data Sources
# ===========================

# Récupérer la zone Route53 existante
data "aws_route53_zone" "main" {
  count = var.route53_zone_name != "" ? 1 : 0
  name  = var.route53_zone_name
}

