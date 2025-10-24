# ===========================
# Lambda Generate Report
# ===========================

# Récupérer les valeurs du Secret Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_secret_arn
}

locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

# IAM Role pour Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.environment}-lambda-generate-report-role"

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
}

# Policy pour S3, Secrets Manager et CloudWatch Logs
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.project}-${var.environment}-lambda-generate-report-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "arn:aws:s3:::${var.reports_bucket}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.db_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "${var.project}-${var.environment}-lambda-logs-attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Fonction Lambda
resource "aws_lambda_function" "generate_report" {
  function_name    = "${var.project}-${var.environment}-lambda-generate-report"
  filename         = "${path.module}/files/handler.zip"
  source_code_hash = filebase64sha256("${path.module}/files/handler.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11"
  timeout          = 30

  environment {
    variables = {
      # S3
      REPORTS_BUCKET = var.reports_bucket

      # Credentials DB depuis Secret Manager
      DB_HOST     = local.db_credentials.url
      DB_PORT     = ""
      DB_NAME     = ""
      DB_USERNAME = local.db_credentials.username
      DB_PASSWORD = local.db_credentials.password
    }
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.generate_report.function_name}"
  retention_in_days = 7
}