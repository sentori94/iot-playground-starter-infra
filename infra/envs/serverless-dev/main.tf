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

  # Calculer l'URL Grafana de manière conditionnelle pour éviter les dépendances circulaires
  # Si grafana_domain_name est défini, on l'utilise (domaine custom HTTPS)
  # Sinon on utilise localhost par défaut (Grafana n'est pas déployé ou sera déployé séparément)
  grafana_url = var.grafana_domain_name != "" ? "https://${var.grafana_domain_name}" : "http://localhost:3000"
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
# Certificat ACM pour les Lambdas
# ===========================
module "acm_lambda_api" {
  count  = var.lambda_api_domain_name != "" && var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/acm_certificate"

  domain_name     = var.lambda_api_domain_name
  route53_zone_id = data.aws_route53_zone.main[0].zone_id
  tags            = local.common_tags
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
  certificate_arn               = length(module.acm_lambda_api) > 0 ? module.acm_lambda_api[0].certificate_validated_arn : ""
  route53_zone_id               = var.route53_zone_name != "" && length(data.aws_route53_zone.main) > 0 ? data.aws_route53_zone.main[0].zone_id : ""
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
  grafana_url               = local.grafana_url
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
# Module VPC Serverless (pour Grafana)
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
# Module ECS Cluster (pour Grafana)
# ===========================
module "ecs_cluster_serverless" {
  source = "../../modules/serverless/ecs_cluster"

  project     = var.project
  environment = var.env
  tags        = local.common_tags
}

# ===========================
# IAM Role pour Grafana accéder à CloudWatch
# ===========================
resource "aws_iam_role" "grafana_cloudwatch" {
  name = "${var.project}-grafana-cw-${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "${var.project}-grafana-cw-access-${var.env}"
  role = aws_iam_role.grafana_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:StopQuery"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===========================
# Certificat ACM pour Grafana
# ===========================
module "acm_grafana" {
  count  = var.grafana_domain_name != "" && var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/acm_certificate"

  domain_name     = var.grafana_domain_name
  route53_zone_id = data.aws_route53_zone.main[0].zone_id
  tags            = local.common_tags
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
  certificate_arn        = var.grafana_domain_name != "" && length(module.acm_grafana) > 0 ? module.acm_grafana[0].certificate_validated_arn : ""
  route53_zone_id        = var.grafana_domain_name != "" && length(data.aws_route53_zone.main) > 0 ? data.aws_route53_zone.main[0].zone_id : ""
  grafana_task_role_arn  = aws_iam_role.grafana_cloudwatch.arn
  tags                   = local.common_tags
}

# ===========================
# Data Sources
# ===========================

# Récupérer la zone Route53 existante
data "aws_route53_zone" "main" {
  count = var.route53_zone_name != "" ? 1 : 0
  name  = var.route53_zone_name
}

