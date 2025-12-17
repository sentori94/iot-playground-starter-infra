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
# Data: Certificat ACM (depuis serverless-dev)
# ===========================
# On récupère le certificat wildcard *.sentori-studio.com créé par serverless-dev
data "aws_acm_certificate" "lambda_api" {
  count       = var.grafana_domain_name != "" ? 1 : 0
  domain      = "*.${var.route53_zone_name}"
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
  certificate_arn        = var.grafana_domain_name != "" && length(data.aws_acm_certificate.lambda_api) > 0 ? data.aws_acm_certificate.lambda_api[0].arn : ""
  route53_zone_id        = var.route53_zone_name != "" && length(data.aws_route53_zone.main) > 0 ? data.aws_route53_zone.main[0].zone_id : ""
  grafana_task_role_arn  = aws_iam_role.grafana_cloudwatch.arn
  tags                   = local.common_tags
}

