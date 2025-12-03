# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.environment}-infra-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-infra-manager-role"
    Environment = var.environment
    Project     = var.project
  }
}

# DynamoDB Table for Deployment Status
resource "aws_dynamodb_table" "deployments" {
  name           = "${var.project}-${var.environment}-deployments"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "deployment_id"

  attribute {
    name = "deployment_id"
    type = "S"
  }

  attribute {
    name = "environment"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  global_secondary_index {
    name            = "environment-created-index"
    hash_key        = "environment"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "${var.project}-${var.environment}-deployments"
    Environment = var.environment
    Project     = var.project
  }
}

# Secrets Manager pour stocker le GitHub token
resource "aws_secretsmanager_secret" "github_token" {
  name        = "${var.project}-${var.environment}-github-token"
  description = "GitHub Personal Access Token for triggering workflows"

  tags = {
    Name        = "${var.project}-${var.environment}-github-token"
    Environment = var.environment
    Project     = var.project
  }
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy (if Lambda runs in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = length(var.subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom policy for infrastructure management
resource "aws_iam_role_policy" "lambda_infra_management" {
  name = "${var.project}-${var.environment}-infra-management-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.deployments.arn,
          "${aws_dynamodb_table.deployments.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.github_token.arn
      }
    ]
  })
}

# Lambda Function - Create Infrastructure
resource "aws_lambda_function" "create_infra" {
  function_name    = "${var.project}-${var.environment}-create-infra"
  filename         = "${path.module}/files/create_infra.zip"
  source_code_hash = filebase64sha256("${path.module}/files/create_infra.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT               = var.environment
      PROJECT                   = var.project
      AWS_REGION                = var.aws_region
      DEPLOYMENTS_TABLE         = aws_dynamodb_table.deployments.name
      GITHUB_TOKEN_SECRET       = aws_secretsmanager_secret.github_token.name
      GITHUB_REPO_OWNER         = var.github_repo_owner
      GITHUB_REPO_NAME          = var.github_repo_name
      GITHUB_WORKFLOW_FILE      = "bootstrap.yml"
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-create-infra"
    Environment = var.environment
    Project     = var.project
  }
}

# Lambda Function - Check Status
resource "aws_lambda_function" "check_status" {
  function_name    = "${var.project}-${var.environment}-check-status"
  filename         = "${path.module}/files/check_status.zip"
  source_code_hash = filebase64sha256("${path.module}/files/check_status.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT               = var.environment
      PROJECT                   = var.project
      AWS_REGION                = var.aws_region
      DEPLOYMENTS_TABLE         = aws_dynamodb_table.deployments.name
      GITHUB_TOKEN_SECRET       = aws_secretsmanager_secret.github_token.name
      GITHUB_REPO_OWNER         = var.github_repo_owner
      GITHUB_REPO_NAME          = var.github_repo_name
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-check-status"
    Environment = var.environment
    Project     = var.project
  }
}

# Lambda Function - Destroy Infrastructure
resource "aws_lambda_function" "destroy_infra" {
  function_name    = "${var.project}-${var.environment}-destroy-infra"
  filename         = "${path.module}/files/destroy_infra.zip"
  source_code_hash = filebase64sha256("${path.module}/files/destroy_infra.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  environment {
    variables = {
      ENVIRONMENT                = var.environment
      PROJECT                    = var.project
      AWS_REGION                 = var.aws_region
      DEPLOYMENTS_TABLE          = aws_dynamodb_table.deployments.name
      GITHUB_TOKEN_SECRET        = aws_secretsmanager_secret.github_token.name
      GITHUB_REPO_OWNER          = var.github_repo_owner
      GITHUB_REPO_NAME           = var.github_repo_name
      GITHUB_WORKFLOW_FILE       = "terraform-destroy.yml"
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  tags = {
    Name        = "${var.project}-${var.environment}-destroy-infra"
    Environment = var.environment
    Project     = var.project
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "create_infra_logs" {
  name              = "/aws/lambda/${aws_lambda_function.create_infra.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "check_status_logs" {
  name              = "/aws/lambda/${aws_lambda_function.check_status.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "destroy_infra_logs" {
  name              = "/aws/lambda/${aws_lambda_function.destroy_infra.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# API Gateway HTTP API
resource "aws_apigatewayv2_api" "infra_manager" {
  name          = "${var.project}-${var.environment}-infra-manager"
  protocol_type = "HTTP"
  description   = "API Gateway for Infrastructure Management"

  cors_configuration {
    allow_origins = ["*"] # À personnaliser selon vos besoins
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.project}-${var.environment}-infra-manager-api"
    Environment = var.environment
    Project     = var.project
  }
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.infra_manager.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project}-${var.environment}-infra-manager"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# Lambda Integrations
resource "aws_apigatewayv2_integration" "create_infra" {
  api_id           = aws_apigatewayv2_api.infra_manager.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.create_infra.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "check_status" {
  api_id           = aws_apigatewayv2_api.infra_manager.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.check_status.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "destroy_infra" {
  api_id           = aws_apigatewayv2_api.infra_manager.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.destroy_infra.invoke_arn
  payload_format_version = "2.0"
}

# API Routes
resource "aws_apigatewayv2_route" "create_infra" {
  api_id    = aws_apigatewayv2_api.infra_manager.id
  route_key = "POST /infra/create"
  target    = "integrations/${aws_apigatewayv2_integration.create_infra.id}"
}

resource "aws_apigatewayv2_route" "check_status" {
  api_id    = aws_apigatewayv2_api.infra_manager.id
  route_key = "GET /infra/status/{deploymentId}"
  target    = "integrations/${aws_apigatewayv2_integration.check_status.id}"
}

resource "aws_apigatewayv2_route" "destroy_infra" {
  api_id    = aws_apigatewayv2_api.infra_manager.id
  route_key = "POST /infra/destroy"
  target    = "integrations/${aws_apigatewayv2_integration.destroy_infra.id}"
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "create_infra_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_infra.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.infra_manager.execution_arn}/*/*"
}

resource "aws_lambda_permission" "check_status_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.infra_manager.execution_arn}/*/*"
}

resource "aws_lambda_permission" "destroy_infra_api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.destroy_infra.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.infra_manager.execution_arn}/*/*"
}
