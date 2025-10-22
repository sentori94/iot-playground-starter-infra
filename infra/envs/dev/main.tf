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
  eip_allocation_id   = var.bastion_eip_allocation_id
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
  db_username               = var.db_username
  skip_final_snapshot       = true
  deletion_protection       = false
  publicly_accessible       = true
  multi_az                  = false
  backup_retention_period   = 1
  auto_minor_version_upgrade = true
  tags                      = local.common_tags
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
  secret_arns        = [module.database.secret_arn]

  environment_variables = [
    {
      name  = "APP_GRAFANA_BASE_URL"
      value = "http://${module.grafana_alb.alb_dns_name}"
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
    }
  ]

  container_health_check = {
    command     = ["CMD-SHELL", "curl -fsS http://localhost:${var.container_port}/actuator/health || exit 1"]
    interval    = 30
    timeout     = 5
    retries     = 3
    startPeriod = 60
  }

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
# Templates pour Prometheus et Grafana
# ===========================
data "template_file" "prometheus_config" {
  template = file("${path.module}/templates/prometheus.yml.tpl")
  vars = {
    spring_alb_dns = module.spring_app_alb.alb_dns_name
  }
}

resource "local_file" "prometheus_config_rendered" {
  content  = data.template_file.prometheus_config.rendered
  filename = "${path.module}/templates/prometheus.yml"
}

data "template_file" "grafana_datasource" {
  template = file("${path.module}/templates/grafana-datasource-prometheus.yml.tpl")
  vars = {
    prometheus_alb_dns = module.prometheus_alb.alb_dns_name
  }
}

resource "local_file" "grafana_datasource_rendered" {
  content  = data.template_file.grafana_datasource.rendered
  filename = "${path.module}/templates/grafana-datasource-prometheus.yml"
}

