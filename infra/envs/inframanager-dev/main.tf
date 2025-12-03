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
}

