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

resource "aws_iam_policy" "lambda_policy" {
  name   = "${var.project}-${var.environment}-lambda-generate-report-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject"],
        Resource = "arn:aws:s3:::${var.reports_bucket}/*"
      },
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"],
        Resource = var.db_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.project}-${var.environment}-lambda-generate-report-attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "generate_report" {
  function_name    = "${var.project}-${var.environment}-lambda-generate-report"
  filename         = "${path.module}/files/handler.zip"
  source_code_hash = filebase64sha256("${path.module}/files/handler.zip")
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      DB_SECRET_ARN  = var.db_secret_arn
      REPORTS_BUCKET = var.reports_bucket
    }
  }
}

output "lambda_arn" {
  value = aws_lambda_function.generate_report.arn
}