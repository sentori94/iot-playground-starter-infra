# ===========================
# Athena Configuration pour DynamoDB
# ===========================

# S3 Bucket pour les résultats de requêtes Athena
resource "aws_s3_bucket" "athena_results" {
  bucket = "${var.project}-athena-results-${var.environment}"

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "athena_results" {
  bucket = aws_s3_bucket.athena_results.id

  rule {
    id     = "delete-old-results"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}

# Workgroup Athena
resource "aws_athena_workgroup" "grafana" {
  name = "${var.project}-grafana-${var.environment}"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/results/"
    }
  }

  tags = var.tags
}

# Database Athena pour DynamoDB
resource "aws_athena_database" "iot_data" {
  name   = "${replace(var.project, "-", "_")}_${var.environment}"
  bucket = aws_s3_bucket.athena_results.bucket
}

# Table externe Athena pour Runs (DynamoDB)
resource "aws_athena_named_query" "create_runs_table" {
  name      = "create-runs-table"
  database  = aws_athena_database.iot_data.name
  workgroup = aws_athena_workgroup.grafana.name

  query = <<-SQL
    CREATE EXTERNAL TABLE IF NOT EXISTS runs (
      id string,
      username string,
      status string,
      startedAt string,
      finishedAt string,
      params string,
      errorMessage string,
      grafanaUrl string
    )
    STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
    TBLPROPERTIES (
      "dynamodb.table.name" = "${var.runs_table_name}",
      "dynamodb.column.mapping" = "id:id,username:username,status:status,startedAt:startedAt,finishedAt:finishedAt,params:params,errorMessage:errorMessage,grafanaUrl:grafanaUrl"
    );
  SQL
}

# Table externe Athena pour SensorData (DynamoDB)
resource "aws_athena_named_query" "create_sensor_data_table" {
  name      = "create-sensor-data-table"
  database  = aws_athena_database.iot_data.name
  workgroup = aws_athena_workgroup.grafana.name

  query = <<-SQL
    CREATE EXTERNAL TABLE IF NOT EXISTS sensor_data (
      sensorId string,
      timestamp string,
      type string,
      reading double,
      user string,
      runId string
    )
    STORED BY 'org.apache.hadoop.hive.dynamodb.DynamoDBStorageHandler'
    TBLPROPERTIES (
      "dynamodb.table.name" = "${var.sensor_data_table_name}",
      "dynamodb.column.mapping" = "sensorId:sensorId,timestamp:timestamp,type:type,reading:reading,user:user,runId:runId"
    );
  SQL
}

# IAM Role pour Grafana accéder à Athena et DynamoDB
resource "aws_iam_role" "grafana_athena" {
  name = "${var.project}-grafana-athena-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

# Policy pour accès Athena + DynamoDB
resource "aws_iam_role_policy" "grafana_athena" {
  name = "${var.project}-grafana-athena-access-${var.environment}"
  role = aws_iam_role.grafana_athena.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:*"
        ]
        Resource = [
          aws_athena_workgroup.grafana.arn,
          "arn:aws:athena:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:datacatalog/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.athena_results.arn,
          "${aws_s3_bucket.athena_results.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          var.runs_table_arn,
          var.sensor_data_table_arn,
          "${var.runs_table_arn}/index/*",
          "${var.sensor_data_table_arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

