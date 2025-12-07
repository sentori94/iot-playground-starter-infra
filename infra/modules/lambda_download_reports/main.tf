# ===========================
# Lambda Function - Download Reports
# ===========================

# IAM Role pour Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-download-reports-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Policy pour accéder au bucket S3 reports
resource "aws_iam_role_policy" "lambda_s3_policy" {
  name = "${var.project}-download-reports-s3-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.reports_bucket}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = "arn:aws:s3:::${var.reports_bucket}/*"
      }
    ]
  })
}

# Policy pour CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "download_reports" {
  filename         = "${path.module}/files/handler.zip"
  function_name    = "${var.project}-download-reports-${var.environment}"
  role            = aws_iam_role.lambda_role.arn
  handler         = "handler.lambda_handler"
  source_code_hash = filebase64sha256("${path.module}/files/handler.zip")
  runtime         = "python3.11"
  timeout         = 60
  memory_size     = 512

  environment {
    variables = {
      REPORTS_BUCKET = var.reports_bucket
    }
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.download_reports.function_name}"
  retention_in_days = 7
}

# ===========================
# API Gateway REST API
# ===========================

resource "aws_api_gateway_rest_api" "reports_api" {
  name        = "${var.project}-reports-api-${var.environment}"
  description = "API to download all reports from S3"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Resource /download
resource "aws_api_gateway_resource" "download" {
  rest_api_id = aws_api_gateway_rest_api.reports_api.id
  parent_id   = aws_api_gateway_rest_api.reports_api.root_resource_id
  path_part   = "download"
}

# Method GET /download
resource "aws_api_gateway_method" "get_download" {
  rest_api_id   = aws_api_gateway_rest_api.reports_api.id
  resource_id   = aws_api_gateway_resource.download.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

# Integration Lambda
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.reports_api.id
  resource_id = aws_api_gateway_resource.download.id
  http_method = aws_api_gateway_method.get_download.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.download_reports.invoke_arn
}

# Permission pour API Gateway d'invoquer Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.download_reports.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.reports_api.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.reports_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.download.id,
      aws_api_gateway_method.get_download.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.reports_api.id
  stage_name    = var.environment
}

# ===========================
# API Key & Usage Plan
# ===========================

# API Key
resource "aws_api_gateway_api_key" "reports_api_key" {
  name    = "${var.project}-reports-api-key-${var.environment}"
  enabled = true
}

# Usage Plan avec throttling
resource "aws_api_gateway_usage_plan" "reports_usage_plan" {
  name        = "${var.project}-reports-usage-plan-${var.environment}"
  description = "Usage plan for reports API with rate limiting"

  api_stages {
    api_id = aws_api_gateway_rest_api.reports_api.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_throttle_rate_limit
    burst_limit = var.api_throttle_burst_limit
  }

  quota_settings {
    limit  = 100
    period = "DAY"
  }
}

# Link API Key to Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.reports_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.reports_usage_plan.id
}

# ===========================
# Secrets Manager pour l'API Key
# ===========================

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${var.project}-reports-api-key-${var.environment}"
  description             = "API Key for reports download API Gateway"
  recovery_window_in_days = 0

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    api_key = aws_api_gateway_api_key.reports_api_key.value
  })
}

# ===========================
# Custom Domain pour API Gateway (optionnel)
# ===========================

resource "aws_api_gateway_domain_name" "custom_domain" {
  count = var.domain_name != "" ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Mapping du domaine personnalisé vers l'API et le stage
resource "aws_api_gateway_base_path_mapping" "custom_domain_mapping" {
  count = var.domain_name != "" ? 1 : 0

  api_id      = aws_api_gateway_rest_api.reports_api.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.custom_domain[0].domain_name
}

# Enregistrement Route53 pour le domaine personnalisé
resource "aws_route53_record" "api_domain" {
  count = var.domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.custom_domain[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.custom_domain[0].regional_zone_id
    evaluate_target_health = true
  }
}
