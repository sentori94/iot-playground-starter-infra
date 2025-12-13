output "runs_table_name" {
  description = "Name of the Runs DynamoDB table"
  value       = aws_dynamodb_table.runs.name
}

output "runs_table_arn" {
  description = "ARN of the Runs DynamoDB table"
  value       = aws_dynamodb_table.runs.arn
}

output "sensor_data_table_name" {
  description = "Name of the SensorData DynamoDB table"
  value       = aws_dynamodb_table.sensor_data.name
}

output "sensor_data_table_arn" {
  description = "ARN of the SensorData DynamoDB table"
  value       = aws_dynamodb_table.sensor_data.arn
}

