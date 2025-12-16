# ===========================
# API Gateway REST API pour IoT Lambda
# ===========================

resource "aws_api_gateway_rest_api" "lambda_iot" {
  name        = "${var.project}-lambda-api-${var.environment}"
  description = "API Gateway pour les lambdas IoT (Run & Sensor)"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

# ===========================
# Resources & Routes pour Run API
# ===========================

# /api
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_rest_api.lambda_iot.root_resource_id
  path_part   = "api"
}

# /api/runs
resource "aws_api_gateway_resource" "runs" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "runs"
}

# /api/runs/all
resource "aws_api_gateway_resource" "runs_all" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs.id
  path_part   = "all"
}

# /api/runs/{id}
resource "aws_api_gateway_resource" "runs_id" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs.id
  path_part   = "{id}"
}

# GET /api/runs
resource "aws_api_gateway_method" "runs_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs.id
  http_method = aws_api_gateway_method.runs_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# GET /api/runs/all
resource "aws_api_gateway_method" "runs_all_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_all.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_all_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_all.id
  http_method = aws_api_gateway_method.runs_all_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# GET /api/runs/{id}
resource "aws_api_gateway_method" "runs_id_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_id.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_id_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id.id
  http_method = aws_api_gateway_method.runs_id_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# /api/runs/can-start
resource "aws_api_gateway_resource" "runs_can_start" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs.id
  path_part   = "can-start"
}

# GET /api/runs/can-start
resource "aws_api_gateway_method" "runs_can_start_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_can_start.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_can_start_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_can_start.id
  http_method = aws_api_gateway_method.runs_can_start_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# /api/runs/start
resource "aws_api_gateway_resource" "runs_start" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs.id
  path_part   = "start"
}

# POST /api/runs/start
resource "aws_api_gateway_method" "runs_start_post" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_start.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_start_post" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_start.id
  http_method = aws_api_gateway_method.runs_start_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# /api/runs/running
resource "aws_api_gateway_resource" "runs_running" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs.id
  path_part   = "running"
}

# GET /api/runs/running
resource "aws_api_gateway_method" "runs_running_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_running.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_running_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_running.id
  http_method = aws_api_gateway_method.runs_running_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# /api/runs/{id}/finish
resource "aws_api_gateway_resource" "runs_id_finish" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.runs_id.id
  path_part   = "finish"
}

# POST /api/runs/{id}/finish
resource "aws_api_gateway_method" "runs_id_finish_post" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.runs_id_finish.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "runs_id_finish_post" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.runs_id_finish.id
  http_method = aws_api_gateway_method.runs_id_finish_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_run_api_invoke_arn
}

# ===========================
# Resources & Routes pour Sensor API
# ===========================

# /api/sensors
resource "aws_api_gateway_resource" "sensors" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "sensors"
}

# /api/sensors/data
resource "aws_api_gateway_resource" "sensors_data" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  parent_id   = aws_api_gateway_resource.sensors.id
  path_part   = "data"
}

# POST /sensors/data
resource "aws_api_gateway_method" "sensors_data_post" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.sensors_data.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sensors_data_post" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.sensors_data.id
  http_method = aws_api_gateway_method.sensors_data_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_sensor_api_invoke_arn
}

# GET /sensors/data
resource "aws_api_gateway_method" "sensors_data_get" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  resource_id   = aws_api_gateway_resource.sensors_data.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "sensors_data_get" {
  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id
  resource_id = aws_api_gateway_resource.sensors_data.id
  http_method = aws_api_gateway_method.sensors_data_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_sensor_api_invoke_arn
}


# ===========================
# Deployment
# ===========================

resource "aws_api_gateway_deployment" "lambda_iot" {
  depends_on = [
    aws_api_gateway_integration.runs_get,
    aws_api_gateway_integration.runs_all_get,
    aws_api_gateway_integration.runs_id_get,
    aws_api_gateway_integration.runs_can_start_get,
    aws_api_gateway_integration.runs_start_post,
    aws_api_gateway_integration.runs_running_get,
    aws_api_gateway_integration.runs_id_finish_post,
    aws_api_gateway_integration.sensors_data_post,
    aws_api_gateway_integration.sensors_data_get,
  ]

  rest_api_id = aws_api_gateway_rest_api.lambda_iot.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.runs.id,
      aws_api_gateway_resource.runs_start.id,
      aws_api_gateway_resource.runs_can_start.id,
      aws_api_gateway_resource.runs_running.id,
      aws_api_gateway_resource.runs_id_finish.id,
      aws_api_gateway_resource.runs_all.id,
      aws_api_gateway_resource.runs_id.id,
      aws_api_gateway_resource.sensors.id,
      aws_api_gateway_resource.sensors_data.id,
      aws_api_gateway_method.runs_get.id,
      aws_api_gateway_method.runs_start_post.id,
      aws_api_gateway_method.runs_can_start_get.id,
      aws_api_gateway_method.runs_running_get.id,
      aws_api_gateway_method.runs_id_finish_post.id,
      aws_api_gateway_method.sensors_data_post.id,
      aws_api_gateway_method.sensors_data_get.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "lambda_iot" {
  deployment_id = aws_api_gateway_deployment.lambda_iot.id
  rest_api_id   = aws_api_gateway_rest_api.lambda_iot.id
  stage_name    = var.environment

  tags = var.tags
}

# ===========================
# Custom Domain (optionnel)
# ===========================

resource "aws_api_gateway_domain_name" "lambda_iot" {
  count = var.custom_domain_name != "" ? 1 : 0

  domain_name              = var.custom_domain_name
  regional_certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags

  # Attendre que le certificat soit créé
  depends_on = []
}

resource "aws_api_gateway_base_path_mapping" "lambda_iot" {
  count = var.custom_domain_name != "" ? 1 : 0

  api_id      = aws_api_gateway_rest_api.lambda_iot.id
  stage_name  = aws_api_gateway_stage.lambda_iot.stage_name
  domain_name = aws_api_gateway_domain_name.lambda_iot[0].domain_name
}

# Route53 Record pour le custom domain
resource "aws_route53_record" "lambda_iot" {
  count = var.custom_domain_name != "" && var.route53_zone_id != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = aws_api_gateway_domain_name.lambda_iot[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.lambda_iot[0].regional_zone_id
    evaluate_target_health = false
  }
}

