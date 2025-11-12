# ===========================
# AWS X-Ray Secrets Module
# ===========================

resource "aws_secretsmanager_secret" "xray_credentials" {
  name                    = "${var.project}-xray-credentials-${var.environment}"
  description             = "AWS X-Ray credentials for ${var.project} ${var.environment}"
  recovery_window_in_days = 0

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "xray_credentials" {
  secret_id = aws_secretsmanager_secret.xray_credentials.id
  secret_string = jsonencode({
    access_key_id     = var.xray_access_key_id
    secret_access_key = var.xray_secret_access_key
  })
}

