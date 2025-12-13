# ===========================
# Lambda Function pour Run API
# ===========================

data "archive_file" "lambda_run_api" {
  type        = "zip"
  source_dir  = "${path.module}/files"
  output_path = "${path.module}/lambda_run_api.zip"
}

resource "aws_lambda_function" "run_api" {
  filename         = data.archive_file.lambda_run_api.output_path
  function_name    = "${var.project}-run-api-${var.environment}"
  role            = aws_iam_role.lambda_run_api.arn
  handler         = "handler.lambda_handler"
  source_code_hash = data.archive_file.lambda_run_api.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30
  memory_size     = 512

  environment {
    variables = {
      RUNS_TABLE_NAME = var.runs_table_name
      ENVIRONMENT     = var.environment
    }
  }

  tags = var.tags
}

# IAM Role pour Lambda
resource "aws_iam_role" "lambda_run_api" {
  name = "${var.project}-lambda-run-api-${var.environment}"

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

  tags = var.tags
}

# Policy pour logs CloudWatch
resource "aws_iam_role_policy_attachment" "lambda_run_api_logs" {
  role       = aws_iam_role.lambda_run_api.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy pour DynamoDB
resource "aws_iam_role_policy" "lambda_run_api_dynamodb" {
  name = "${var.project}-lambda-run-api-dynamodb-${var.environment}"
  role = aws_iam_role.lambda_run_api.id

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
          var.runs_table_arn,
          "${var.runs_table_arn}/index/*"
        ]
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda_run_api" {
  name              = "/aws/lambda/${aws_lambda_function.run_api.function_name}"
  retention_in_days = 14

  tags = var.tags
}

# Permission pour API Gateway d'invoquer la Lambda
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.run_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

