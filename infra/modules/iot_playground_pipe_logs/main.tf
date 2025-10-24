data "aws_caller_identity" "current" {}

# Permission pour chaque Lambda
resource "aws_lambda_permission" "allow_logs_invoke" {
  count         = length(var.lambda_target_arns)
  statement_id  = "AllowExecutionFromCloudWatch-${count.index}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_target_arns[count.index]
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
}

# Subscription filter pour chaque Lambda
resource "aws_cloudwatch_log_subscription_filter" "run_finished" {
  count           = length(var.lambda_target_arns)
  name            = "${var.project}-${var.environment}-subscription-${count.index}"
  log_group_name  = var.log_group_name
  filter_pattern  = var.filter_pattern
  destination_arn = var.lambda_target_arns[count.index]

  depends_on = [aws_lambda_permission.allow_logs_invoke]
}