locals {
  common_tags = {
    Project      = var.project
    Environment  = var.env
    ManagedBy    = "Terraform"
    Architecture = "Serverless-Grafana"
  }
}

# ===========================
# Module VPC Serverless
# ===========================
module "vpc_serverless" {
  source = "../../modules/serverless/vpc"

  project            = var.project
  environment        = var.env
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  tags               = local.common_tags
}

# ===========================
# Module ECS Cluster
# ===========================
module "ecs_cluster_serverless" {
  source = "../../modules/serverless/ecs_cluster"

  project     = var.project
  environment = var.env
  tags        = local.common_tags
}

# ===========================
# Data: DynamoDB Tables (depuis serverless-dev)
# ===========================
data "aws_dynamodb_table" "runs" {
  name = "iot-playground-runs-serverless-dev"
}

data "aws_dynamodb_table" "sensor_data" {
  name = "iot-playground-sensor-data-serverless-dev"
}

# ===========================
# Module Athena pour DynamoDB
# ===========================
module "athena_dynamodb" {
  source = "../../modules/serverless/athena_dynamodb"

  project                = var.project
  environment            = var.env
  runs_table_name        = data.aws_dynamodb_table.runs.name
  runs_table_arn         = data.aws_dynamodb_table.runs.arn
  sensor_data_table_name = data.aws_dynamodb_table.sensor_data.name
  sensor_data_table_arn  = data.aws_dynamodb_table.sensor_data.arn
  tags                   = local.common_tags
}

# ===========================
# Data: Certificat ACM (depuis serverless-dev)
# ===========================
data "aws_acm_certificate" "lambda_api" {
  domain      = "sentori-studio.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

# ===========================
# Data: Route53 Zone
# ===========================
data "aws_route53_zone" "main" {
  count = var.route53_zone_name != "" ? 1 : 0
  name  = var.route53_zone_name
}

# ===========================
# Module Grafana ECS
# ===========================
module "grafana_serverless" {
  source = "../../modules/serverless/grafana_ecs"

  project                = var.project
  environment            = var.env
  vpc_id                 = module.vpc_serverless.vpc_id
  public_subnet_ids      = module.vpc_serverless.public_subnet_ids
  private_subnet_ids     = module.vpc_serverless.private_subnet_ids
  ecs_cluster_id         = module.ecs_cluster_serverless.cluster_id
  grafana_image_uri      = var.grafana_image_uri
  grafana_image_tag      = var.grafana_image_tag
  grafana_admin_password = var.grafana_admin_password
  custom_domain_name     = var.grafana_domain_name
  certificate_arn        = data.aws_acm_certificate.lambda_api.arn
  route53_zone_id        = var.route53_zone_name != "" ? data.aws_route53_zone.main[0].zone_id : ""
  grafana_task_role_arn  = module.athena_dynamodb.grafana_task_role_arn
  athena_workgroup_name  = module.athena_dynamodb.athena_workgroup_name
  athena_database_name   = module.athena_dynamodb.athena_database_name
  tags                   = local.common_tags
}

