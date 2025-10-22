resource "aws_lambda_permission" "allow_logs_invoke" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_target_arn
  principal     = "logs.amazonaws.com"
  source_arn    = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.log_group_name}:*"
}

data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_subscription_filter" "run_finished" {
  name            = "${var.project}-${var.environment}-subscription"
  log_group_name  = var.log_group_name
  filter_pattern  = var.filter_pattern
  destination_arn = var.lambda_target_arn
}