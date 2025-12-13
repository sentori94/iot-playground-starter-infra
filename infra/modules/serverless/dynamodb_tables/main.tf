# ===========================
# Module DynamoDB Tables pour IoT Playground
# ===========================

# Table Runs
resource "aws_dynamodb_table" "runs" {
  name           = "${var.project}-runs-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST" # On-demand pour serverless
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S" # UUID sous forme de string
  }

  attribute {
    name = "username"
    type = "S"
  }

  attribute {
    name = "startedAt"
    type = "S" # ISO8601 timestamp pour tri
  }

  # GSI pour requêtes par username
  global_secondary_index {
    name            = "username-startedAt-index"
    hash_key        = "username"
    range_key       = "startedAt"
    projection_type = "ALL"
  }

  # GSI pour tri par startedAt (pour /api/runs/all)
  global_secondary_index {
    name            = "startedAt-index"
    hash_key        = "startedAt"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-runs-${var.environment}"
    }
  )
}

# Table SensorData
resource "aws_dynamodb_table" "sensor_data" {
  name           = "${var.project}-sensor-data-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "sensorId"
  range_key      = "timestamp"

  attribute {
    name = "sensorId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S" # ISO8601 timestamp
  }

  attribute {
    name = "runId"
    type = "S"
  }

  # GSI pour requêtes par runId
  global_secondary_index {
    name            = "runId-timestamp-index"
    hash_key        = "runId"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-sensor-data-${var.environment}"
    }
  )
}

