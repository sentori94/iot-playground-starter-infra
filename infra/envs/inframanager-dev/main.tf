# ===========================
# Infrastructure Manager
# Module pour gérer l'infrastructure via API Gateway + Lambda
# ===========================

# Module Route53 (si configuré)
module "route53" {
  count  = var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/route53"

  route53_zone_name = var.route53_zone_name
  records           = [] # Pas d'enregistrements ALB pour inframanager
}

# Certificat ACM pour Infrastructure Manager (si domaine configuré)
module "acm_infra_manager" {
  count  = var.infra_manager_domain_name != "" && var.route53_zone_name != "" ? 1 : 0
  source = "../../modules/acm_certificate"

  domain_name     = var.infra_manager_domain_name
  route53_zone_id = module.route53[0].zone_id

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "infra_manager" {
  source = "../../modules/lambda_infra_manager"

  project                         = var.project
  environment                     = var.environment
  aws_region                      = var.aws_region
  terraform_state_bucket          = var.state_bucket_name
  terraform_state_dynamodb_table  = "terraform-locks"

  # Configuration GitHub
  github_repo_owner = var.github_repo_owner
  github_repo_name  = var.github_repo_name

  # Configuration du domaine personnalisé (optionnel)
  domain_name      = var.infra_manager_domain_name
  route53_zone_id  = var.route53_zone_name != "" ? module.route53[0].zone_id : ""
  # Utiliser le certificat VALIDÉ pour garantir qu'il est prêt
  certificate_arn  = var.infra_manager_domain_name != "" && var.route53_zone_name != "" ? module.acm_infra_manager[0].certificate_validated_arn : ""

  # Configuration Auto-Destroy
  enable_auto_destroy                  = true
  notification_email                   = "walid.lamkharbech@gmail.com"
  auto_destroy_cloudwatch_log_group    = "/ecs/${var.project}-spring-app-${var.environment}"
  auto_destroy_log_filter_pattern      = "finished SUCCESS"
  auto_destroy_idle_threshold_hours    = 2
  auto_destroy_check_schedule          = "rate(1 hour)"

  depends_on = [
    module.route53,
    module.acm_infra_manager
  ]
}
