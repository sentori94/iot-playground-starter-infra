# ===========================
# Infrastructure Manager
# Module pour gérer l'infrastructure via API Gateway + Lambda
# ===========================

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

  # Configuration Auto-Destroy
  enable_auto_destroy                  = true
  notification_email                   = "walid.lamkharbech@gmail.com"
  auto_destroy_cloudwatch_log_group    = "/ecs/${var.project}-spring-app-${var.environment}"
  auto_destroy_log_filter_pattern      = "finished SUCCESS"
  auto_destroy_idle_threshold_hours    = 2
  auto_destroy_check_schedule          = "rate(1 hour)"
}
