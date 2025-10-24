resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-${var.environment}-lambda-notify-role"

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

resource "aws_iam_policy_attachment" "lambda_logs" {
  name       = "${var.project}-${var.environment}-lambda-logs-attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "notify" {
  function_name = "${var.project}-${var.environment}-lambda-notify"
  filename      = "${path.module}/files/handler.zip"
  source_code_hash = filebase64sha256("${path.module}/files/handler.zip")
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 5
  environment {
    variables = {
      DB_SECRET_ARN  = var.db_secret_arn
      REPORTS_BUCKET = "iot-playground-reports"
    }
  }
}

# Log group for the Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.notify.function_name}"
  retention_in_days = 7
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = ["s3:PutObject"]
    resources = ["arn:aws:s3:::iot-playground-reports/*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}
