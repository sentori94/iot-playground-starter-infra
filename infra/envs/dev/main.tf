# ===========================
# Configuration Terraform avec Modules
# ===========================

locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# ===========================
# Module Network
# ===========================
module "network" {
  source = "../../modules/network"

  project                = var.project
  environment            = var.env
  aws_region             = var.aws_region
  vpc_cidr               = "10.30.0.0/16"
  public_subnet_cidrs    = ["10.30.0.0/24", "10.30.1.0/24"]
  private_subnet_cidrs   = ["10.30.10.0/24", "10.30.11.0/24"]
  availability_zones     = ["a", "b"]
  tags                   = local.common_tags
}

# ===========================
# Module ECS Cluster
# ===========================
module "ecs_cluster" {
  source = "../../modules/ecs"

  cluster_name = "${var.project}-cluster-${var.env}"
  tags         = local.common_tags
}

# ===========================
# Module Bastion
# ===========================
module "bastion" {
  source = "../../modules/bastion"

  name                = "${var.project}-bastion-${var.env}"
  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.public_subnet_ids[0]
  instance_type       = "t3.micro"
  key_name            = var.bastion_key_name
  allowed_cidr_blocks = [var.my_ip]
  tags                = local.common_tags
}

# ===========================
# Module Database (RDS)
# ===========================
module "database" {
  source = "../../modules/database"

  project                   = var.project
  environment               = var.env
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  allowed_security_groups   = [
    module.spring_app_sg.ecs_security_group_id,
    module.bastion.security_group_id
  ]
  instance_class            = var.rds_instance_class
  allocated_storage         = 20
  db_name                   = var.db_name
  skip_final_snapshot       = true
  deletion_protection       = false
  publicly_accessible       = true
  multi_az                  = false
  backup_retention_period   = 1
  auto_minor_version_upgrade = true
  tags                      = local.common_tags
}

# ===========================
# Module AWS X-Ray Secrets
# ===========================
module "xray_secrets" {
  source = "../../modules/xray_secrets"

  project                = var.project
  environment            = var.env
  xray_access_key_id     = var.xray_access_key_id
  xray_secret_access_key = var.xray_secret_access_key
  tags                   = local.common_tags
}

# ===========================
# Security Groups pour les services
# ===========================
module "spring_app_sg" {
  source = "../../modules/security_groups"

  name                       = "${var.app_name}-${var.env}"
  vpc_id                     = module.network.vpc_id
  container_port             = var.container_port
  allow_prometheus_scraping  = true
  tags                       = local.common_tags
}

module "prometheus_sg" {
  source = "../../modules/security_groups"

  name                       = "${var.project}-prometheus-${var.env}"
  vpc_id                     = module.network.vpc_id
  container_port             = 9090
  allow_prometheus_scraping  = true
  tags                       = local.common_tags
}

module "grafana_sg" {
  source = "../../modules/security_groups"

  name           = "${var.project}-grafana-${var.env}"
  vpc_id         = module.network.vpc_id
  container_port = 3000
  tags           = local.common_tags
}

# ===========================
# ALB pour Spring App
# ===========================
module "spring_app_alb" {
  source = "../../modules/alb"

  name                             = "${var.app_name}-alb-${var.env}"
  vpc_id                           = module.network.vpc_id
  subnet_ids                       = module.network.public_subnet_ids
  security_group_id                = module.spring_app_sg.alb_security_group_id
  internal                         = false
  target_port                      = var.container_port
  listener_port                    = 80
  health_check_path                = var.health_path
  health_check_matcher             = "200-399"
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 5
  tags                             = local.common_tags
}

# ===========================
# ALB pour Prometheus
# ===========================
module "prometheus_alb" {
  source = "../../modules/alb"
  name              = "${var.project}-ptheus-alb-${var.env}"
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.prometheus_sg.alb_security_group_id
  internal          = false
  target_port       = 9090
  listener_port     = 80
  health_check_path = "/-/healthy"
  tags              = local.common_tags
}

# ===========================
# ALB pour Grafana
# ===========================
module "grafana_alb" {
  source = "../../modules/alb"

  name              = "${var.project}-grafa-alb-${var.env}"
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnet_ids
  security_group_id = module.grafana_sg.alb_security_group_id
  internal          = false
  target_port       = 3000
  listener_port     = 80
  health_check_path = "/login"
  tags              = local.common_tags
}

# ===========================
# ECS Service - Spring App
# ===========================
module "spring_app_service" {
  source = "../../modules/ecs_service"

  service_name       = "${var.app_name}-${var.env}"
  cluster_id         = module.ecs_cluster.cluster_id
  image_url          = var.image_url
  container_port     = var.container_port
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = var.desired_count
  subnet_ids         = module.network.private_subnet_ids
  security_group_id  = module.spring_app_sg.ecs_security_group_id
  assign_public_ip   = false
  target_group_arn   = module.spring_app_alb.target_group_arn
  aws_region         = var.aws_region
  log_retention_days = 14
  secret_arns        = [
    module.database.secret_arn,
    module.xray_secrets.secret_arn,
    module.lambda_download_reports.api_key_secret_arn
  ]
  enable_xray        = true

  environment_variables = [
    {
      name  = "APP_GRAFANA_BASE_URL"
      value = "http://${module.grafana_alb.alb_dns_name}"
    },
    {
      name  = "AWS_XRAY_DAEMON_ADDRESS"
      value = "127.0.0.1:2000"
    },
    {
      name  = "REPORTS_API_GATEWAY_URL"
      value = module.lambda_download_reports.api_endpoint
    },
    {
      name  = "CORS_ALLOWED_ORIGINS"
      value = var.frontend_url != "" ? var.frontend_url : "*"
    }
  ]

  secrets = [
    {
      name      = "SPRING_DATASOURCE_URL"
      valueFrom = "${module.database.secret_arn}:url::"
    },
    {
      name      = "SPRING_DATASOURCE_USERNAME"
      valueFrom = "${module.database.secret_arn}:username::"
    },
    {
      name      = "SPRING_DATASOURCE_PASSWORD"
      valueFrom = "${module.database.secret_arn}:password::"
    },
    {
      name      = "XRAY_AWS_ACCESS_KEY_ID"
      valueFrom = "${module.xray_secrets.secret_arn}:access_key_id::"
    },
    {
      name      = "XRAY_AWS_SECRET_ACCESS_KEY"
      valueFrom = "${module.xray_secrets.secret_arn}:secret_access_key::"
    },
    {
      name      = "REPORTS_API_KEY"
      valueFrom = "${module.lambda_download_reports.api_key_secret_arn}:api_key::"
    }
  ]

  container_health_check = {
    command     = ["CMD-SHELL", "curl -fsS http://localhost:${var.container_port}/actuator/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }

  depends_on = [
    module.database,
    module.xray_secrets,
    module.lambda_download_reports
  ]

  tags = local.common_tags
}

# ===========================
# ECS Service - Prometheus
# ===========================
module "prometheus_service" {
  source = "../../modules/ecs_service"

  service_name       = "${var.project}-prometheus-${var.env}"
  cluster_id         = module.ecs_cluster.cluster_id
  image_url          = var.prom_image_ecr
  container_port     = 9090
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = 1
  subnet_ids         = module.network.private_subnet_ids
  security_group_id  = module.prometheus_sg.ecs_security_group_id
  assign_public_ip   = false
  target_group_arn   = module.prometheus_alb.target_group_arn
  aws_region         = var.aws_region
  log_retention_days = 7

  environment_variables = [
    {
      name  = "SPRING_APP_URL"
      value = module.spring_app_alb.alb_dns_name
    }
  ]

  tags = local.common_tags
}

# ===========================
# ECS Service - Grafana
# ===========================
module "grafana_service" {
  source = "../../modules/ecs_service"

  service_name       = "${var.project}-grafana-${var.env}"
  cluster_id         = module.ecs_cluster.cluster_id
  image_url          = var.grafana_image_ecr
  container_port     = 3000
  cpu                = var.ecs_cpu
  memory             = var.ecs_memory
  desired_count      = 1
  subnet_ids         = module.network.private_subnet_ids
  security_group_id  = module.grafana_sg.ecs_security_group_id
  assign_public_ip   = false
  target_group_arn   = module.grafana_alb.target_group_arn
  aws_region         = var.aws_region
  log_retention_days = 7

  environment_variables = [
    {
      name  = "PROMETHEUS_URL"
      value = module.prometheus_alb.alb_dns_name
    },
    {
      name  = "GF_AUTH_ANONYMOUS_ENABLED"
      value = "true"
    },
    {
      name  = "GF_AUTH_ANONYMOUS_ORG_ROLE"
      value = "Admin"
    },
    {
      name  = "GF_AUTH_BASIC_ENABLED"
      value = "false"
    },
    {
      name  = "GF_AUTH_DISABLE_LOGIN_FORM"
      value = "true"
    },
    {
      name  = "GF_SECURITY_ALLOW_EMBEDDING"
      value = "true"
    }
  ]

  tags = local.common_tags
}


# ===========================
# Module S3 Reports et Lambda Generate Report
# ===========================
module "s3_reports" {
  source      = "../../modules/s3_reports"
  project     = var.project
  environment = var.env
}

module "lambda_generate_report" {
  source                = "../../modules/lambda_generate_report"
  project               = var.project
  environment           = var.env
  reports_bucket        = module.s3_reports.bucket_name
  db_secret_arn         = module.database.secret_arn
  vpc_id                = module.network.vpc_id
  subnet_ids            = module.network.private_subnet_ids
  db_security_group_id  = module.database.db_security_group_id

  depends_on = [
    module.database
  ]
}

# ===========================
# CloudWatch Logs - Notification Lambda et Log Pipe
# ===========================
module "iot_playground_lambda_notify" {
  source      = "../../modules/iot_playground_lambda_notify"
  project     = "iot-playground"
  environment = "dev"
}

module "iot_playground_pipe_logs" {
  source             = "../../modules/iot_playground_pipe_logs"
  project            = "iot-playground"
  environment        = "dev"
  log_group_name     = "/ecs/spring-app-dev"
  filter_pattern     = "\"Run\" \"finished\" \"SUCCESS\""
  lambda_target_arns = [
    module.iot_playground_lambda_notify.lambda_arn,
    module.lambda_generate_report.lambda_arn
  ]
}

# ===========================
# Lambda Download Reports + API Gateway
# ===========================
module "lambda_download_reports" {
  source                    = "../../modules/lambda_download_reports"
  project                   = var.project
  environment               = var.env
  reports_bucket            = module.s3_reports.bucket_name
  api_throttle_rate_limit   = 2   # 2 requêtes par seconde
  api_throttle_burst_limit  = 5   # Burst de 5 requêtes max
}

# Note: Les configurations Prometheus et Grafana sont maintenant gérées dynamiquement
# via les variables d'environnement SPRING_APP_URL et PROMETHEUS_URL.
# Plus besoin de templates ni de rebuild des images Docker !

# ===========================
# Module Route53 (optionnel)
# ===========================
module "route53" {
  count  = var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/route53"

  route53_zone_name = var.route53_zone_name

  records = concat(
    var.backend_domain_name != "" ? [{
      name                   = var.backend_domain_name
      alb_dns_name          = module.spring_app_alb.alb_dns_name
      alb_zone_id           = module.spring_app_alb.alb_zone_id
      evaluate_target_health = true
    }] : [],
    var.prometheus_domain_name != "" ? [{
      name                   = var.prometheus_domain_name
      alb_dns_name          = module.prometheus_alb.alb_dns_name
      alb_zone_id           = module.prometheus_alb.alb_zone_id
      evaluate_target_health = true
    }] : [],
    var.grafana_domain_name != "" ? [{
      name                   = var.grafana_domain_name
      alb_dns_name          = module.grafana_alb.alb_dns_name
      alb_zone_id           = module.grafana_alb.alb_zone_id
      evaluate_target_health = true
    }] : []
  )
}
