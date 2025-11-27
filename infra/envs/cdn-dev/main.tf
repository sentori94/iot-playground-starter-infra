# ===========================
# S3 + CloudFront CDN Infrastructure
# ===========================

locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "Terraform"
  }
}

# ===========================
# Module CDN (S3 + CloudFront)
# ===========================
module "cdn" {
  source = "../../modules/cdn"

  project                = var.project
  environment            = var.env
  domain_name            = var.domain_name
  acm_certificate_arn    = var.acm_certificate_arn
  route53_zone_name      = var.route53_zone_name
  tags                   = local.common_tags
}
