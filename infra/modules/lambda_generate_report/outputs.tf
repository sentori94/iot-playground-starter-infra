output "lambda_function_name" {
  description = "Nom de la fonction Lambda"
  value       = aws_lambda_function.generate_report.function_name
}

output "lambda_arn" {
  value = aws_lambda_function.generate_report.arn
}
