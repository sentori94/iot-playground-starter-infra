# ===========================
# CORS Configuration - OPTIONS methods
# ===========================

locals {
  cors_headers = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-User,X-Run-Id'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# ===========================
# OPTIONS /api/runs
# ===========================

resource "aws_api_gateway_method" "runs_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs.id
  http_method = aws_api_gateway_method.runs_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs.id
  http_method = aws_api_gateway_method.runs_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs.id
  http_method = aws_api_gateway_method.runs_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_options]
}

# ===========================
# OPTIONS /api/runs/start
# ===========================

resource "aws_api_gateway_method" "runs_start_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_start.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_start.id
  http_method = aws_api_gateway_method.runs_start_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_start.id
  http_method = aws_api_gateway_method.runs_start_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_start.id
  http_method = aws_api_gateway_method.runs_start_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_start_options]
}

# ===========================
# OPTIONS /api/runs/can-start
# ===========================

resource "aws_api_gateway_method" "runs_can_start_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_can_start.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_can_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_can_start.id
  http_method = aws_api_gateway_method.runs_can_start_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_can_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_can_start.id
  http_method = aws_api_gateway_method.runs_can_start_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_can_start_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_can_start.id
  http_method = aws_api_gateway_method.runs_can_start_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_can_start_options]
}

# ===========================
# OPTIONS /api/runs/running
# ===========================

resource "aws_api_gateway_method" "runs_running_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_running.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_running_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_running.id
  http_method = aws_api_gateway_method.runs_running_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_running_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_running.id
  http_method = aws_api_gateway_method.runs_running_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_running_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_running.id
  http_method = aws_api_gateway_method.runs_running_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_running_options]
}

# ===========================
# OPTIONS /api/runs/{id}
# ===========================

resource "aws_api_gateway_method" "runs_id_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_id.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_id_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id.id
  http_method = aws_api_gateway_method.runs_id_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_id_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id.id
  http_method = aws_api_gateway_method.runs_id_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_id_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id.id
  http_method = aws_api_gateway_method.runs_id_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_id_options]
}

# ===========================
# OPTIONS /api/runs/{id}/finish
# ===========================

resource "aws_api_gateway_method" "runs_id_finish_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_id_finish.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_id_finish_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id_finish.id
  http_method = aws_api_gateway_method.runs_id_finish_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_id_finish_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id_finish.id
  http_method = aws_api_gateway_method.runs_id_finish_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_id_finish_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id_finish.id
  http_method = aws_api_gateway_method.runs_id_finish_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_id_finish_options]
}

# ===========================
# OPTIONS /api/runs/all
# ===========================

resource "aws_api_gateway_method" "runs_all_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_all.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_all_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_all.id
  http_method = aws_api_gateway_method.runs_all_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "runs_all_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_all.id
  http_method = aws_api_gateway_method.runs_all_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "runs_all_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_all.id
  http_method = aws_api_gateway_method.runs_all_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.runs_all_options]
}

# ===========================
# OPTIONS /api/sensors/data
# ===========================

resource "aws_api_gateway_method" "sensors_data_options" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.sensors_data.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sensors_data_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.sensors_data.id
  http_method = aws_api_gateway_method.sensors_data_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "sensors_data_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.sensors_data.id
  http_method = aws_api_gateway_method.sensors_data_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "sensors_data_options" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.sensors_data.id
  http_method = aws_api_gateway_method.sensors_data_options.http_method
  status_code = "200"

  response_parameters = local.cors_headers

  depends_on = [aws_api_gateway_integration.sensors_data_options]
}

