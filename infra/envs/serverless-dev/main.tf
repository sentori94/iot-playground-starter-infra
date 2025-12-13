# ===========================
# Configuration Terraform Serverless
# ===========================

locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
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
# Module Lambda Run API
# ===========================
module "lambda_run_api" {
  source = "../../modules/serverless/lambda_run_api"

  project                   = var.project
  environment               = var.env
  runs_table_name           = module.dynamodb_tables.runs_table_name
  runs_table_arn            = module.dynamodb_tables.runs_table_arn
  api_gateway_execution_arn = module.api_gateway_lambda_iot.api_execution_arn
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
# Module API Gateway Lambda IoT
# ===========================
module "api_gateway_lambda_iot" {
  source = "../../modules/serverless/api_gateway_lambda_iot"

  project                       = var.project
  environment                   = var.env
  lambda_run_api_invoke_arn     = module.lambda_run_api.invoke_arn
  lambda_sensor_api_invoke_arn  = module.lambda_sensor_api.invoke_arn
  custom_domain_name            = var.lambda_api_domain_name
  certificate_arn               = var.lambda_api_domain_name != "" && var.route53_zone_name != "" ? module.acm_lambda_api[0].certificate_validated_arn : ""
  route53_zone_id               = var.route53_zone_name != "" ? data.aws_route53_zone.main[0].zone_id : ""
  tags                          = local.common_tags
}

# ===========================
# ACM Certificate pour Lambda API (optionnel)
# ===========================
module "acm_lambda_api" {
  count  = var.lambda_api_domain_name != "" && var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/acm_certificate"

  domain_name     = var.lambda_api_domain_name
  route53_zone_id = data.aws_route53_zone.main[0].zone_id
  tags            = local.common_tags
}

# ===========================
# Data Sources
# ===========================

# Récupérer la zone Route53 existante
data "aws_route53_zone" "main" {
  count = var.route53_zone_name != "" ? 1 : 0
  name  = var.route53_zone_name
}

