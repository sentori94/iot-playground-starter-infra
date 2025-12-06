# SNS Topic for email notifications
resource "aws_sns_topic" "notifications" {
  name = "${var.project}-${var.environment}-auto-destroy-notifications"

  tags = {
    Name        = "${var.project}-${var.environment}-auto-destroy-notifications"
    Environment = var.environment
    Project     = var.project
  }
}

# SNS Topic Subscription (email)
resource "aws_sns_topic_subscription" "email_notification" {
  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# IAM Role for Lambda
resource "aws_iam_role" "auto_destroy_lambda_role" {
  name = "${var.project}-${var.environment}-auto-destroy-idle-role"

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
    Name        = "${var.project}-${var.environment}-auto-destroy-idle-role"
    Environment = var.environment
    Project     = var.project
  }
}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.auto_destroy_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC execution policy (if Lambda runs in VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = length(var.subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.auto_destroy_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Custom policy for CloudWatch Logs, Secrets Manager, and SNS
resource "aws_iam_role_policy" "auto_destroy_policy" {
  name = "${var.project}-${var.environment}-auto-destroy-policy"
  role = aws_iam_role.auto_destroy_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project}-*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.project}-*:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.github_token_secret_arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.notifications.arn
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "auto_destroy_idle" {
  function_name    = "${var.project}-${var.environment}-auto-destroy-idle"
  filename         = "${path.module}/files/check_idle_and_destroy_handler.zip"
  source_code_hash = filebase64sha256("${path.module}/files/check_idle_and_destroy_handler.zip")
  role             = aws_iam_role.auto_destroy_lambda_role.arn
  handler          = "check_idle_and_destroy_handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      PROJECT               = var.project
      ENVIRONMENT           = var.environment
      GITHUB_TOKEN_SECRET   = var.github_token_secret_arn
      GITHUB_REPO_OWNER     = var.github_repo_owner
      GITHUB_REPO_NAME      = var.github_repo_name
      CLOUDWATCH_LOG_GROUP  = var.cloudwatch_log_group != "" ? var.cloudwatch_log_group : "/ecs/${var.project}-spring-app-${var.environment}"
      LOG_FILTER_PATTERN    = var.log_filter_pattern
      IDLE_THRESHOLD_HOURS  = var.idle_threshold_hours
      SNS_TOPIC_ARN         = aws_sns_topic.notifications.arn
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
    Name        = "${var.project}-${var.environment}-auto-destroy-idle"
    Environment = var.environment
    Project     = var.project
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "auto_destroy_logs" {
  name              = "/aws/lambda/${aws_lambda_function.auto_destroy_idle.function_name}"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# EventBridge Rule to trigger Lambda periodically
resource "aws_cloudwatch_event_rule" "check_idle" {
  name                = "${var.project}-${var.environment}-check-idle-infra"
  description         = "Check for idle infrastructure and trigger auto-destroy"
  schedule_expression = var.check_schedule

  tags = {
    Name        = "${var.project}-${var.environment}-check-idle-infra"
    Environment = var.environment
    Project     = var.project
  }
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "auto_destroy_lambda" {
  rule      = aws_cloudwatch_event_rule.check_idle.name
  target_id = "AutoDestroyIdleLambda"
  arn       = aws_lambda_function.auto_destroy_idle.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_destroy_idle.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_idle.arn
}
