# Exemple : Architecture Modulaire API Gateway

Cette documentation montre comment structurer une infrastructure avec plusieurs Lambdas exposés via une API Gateway réutilisable.

## 📁 Structure des Modules

```
modules/
  api_gateway_base/            # API Gateway + Stage + API Key + Usage Plan
  api_gateway_endpoint/        # Endpoint individuel (resource + method + integration)
  lambda_function/             # Lambda générique réutilisable
```

---

## 🏗️ Module 1 : `api_gateway_base`

Ce module crée l'API Gateway REST API de base, avec stage, API Key et Usage Plan.

### `modules/api_gateway_base/variables.tf`

```terraform
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "api_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "stage_name" {
  description = "Stage name (dev, prod, etc.)"
  type        = string
  default     = "prod"
}

variable "api_throttle_rate_limit" {
  description = "Rate limit per second"
  type        = number
  default     = 10
}

variable "api_throttle_burst_limit" {
  description = "Burst limit"
  type        = number
  default     = 20
}

variable "quota_limit" {
  description = "Daily quota"
  type        = number
  default     = 1000
}
```

### `modules/api_gateway_base/main.tf`

```terraform
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project}-${var.api_name}-${var.environment}"
  description = "API Gateway for ${var.api_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  # Force new deployment on any change
  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name
}

# API Key
resource "aws_api_gateway_api_key" "main" {
  name    = "${var.project}-${var.api_name}-key-${var.environment}"
  enabled = true
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.project}-${var.api_name}-plan-${var.environment}"
  description = "Usage plan for ${var.api_name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_throttle_rate_limit
    burst_limit = var.api_throttle_burst_limit
  }

  quota_settings {
    limit  = var.quota_limit
    period = "DAY"
  }
}

# Link API Key to Usage Plan
resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
```

### `modules/api_gateway_base/outputs.tf`

```terraform
output "rest_api_id" {
  value = aws_api_gateway_rest_api.main.id
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.main.root_resource_id
}

output "stage_name" {
  value = aws_api_gateway_stage.main.stage_name
}

output "invoke_url" {
  value = aws_api_gateway_stage.main.invoke_url
}

output "execution_arn" {
  value = aws_api_gateway_rest_api.main.execution_arn
}

output "api_key_value" {
  value     = aws_api_gateway_api_key.main.value
  sensitive = true
}

output "deployment_id" {
  value = aws_api_gateway_deployment.main.id
}
```

---

## 🔌 Module 2 : `api_gateway_endpoint`

Ce module crée un endpoint individuel (resource + method + integration avec Lambda).

### `modules/api_gateway_endpoint/variables.tf`

```terraform
variable "rest_api_id" {
  description = "API Gateway REST API ID"
  type        = string
}

variable "root_resource_id" {
  description = "Root resource ID of the API"
  type        = string
}

variable "execution_arn" {
  description = "Execution ARN of the API Gateway"
  type        = string
}

variable "path_part" {
  description = "Path part (e.g., 'users', 'reports')"
  type        = string
}

variable "http_method" {
  description = "HTTP method (GET, POST, etc.)"
  type        = string
  default     = "GET"
}

variable "lambda_function_name" {
  description = "Lambda function name to integrate"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda invoke ARN"
  type        = string
}

variable "require_api_key" {
  description = "Require API key for this endpoint"
  type        = bool
  default     = true
}
```

### `modules/api_gateway_endpoint/main.tf`

```terraform
# Resource
resource "aws_api_gateway_resource" "endpoint" {
  rest_api_id = var.rest_api_id
  parent_id   = var.root_resource_id
  path_part   = var.path_part
}

# Method
resource "aws_api_gateway_method" "endpoint" {
  rest_api_id      = var.rest_api_id
  resource_id      = aws_api_gateway_resource.endpoint.id
  http_method      = var.http_method
  authorization    = "NONE"
  api_key_required = var.require_api_key
}

# Integration with Lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.endpoint.id
  http_method = aws_api_gateway_method.endpoint.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# Lambda Permission
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke-${var.path_part}"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.execution_arn}/*/*"
}
```

### `modules/api_gateway_endpoint/outputs.tf`

```terraform
output "resource_id" {
  value = aws_api_gateway_resource.endpoint.id
}

output "method_id" {
  value = aws_api_gateway_method.endpoint.id
}

output "integration_id" {
  value = aws_api_gateway_integration.lambda.id
}

output "path" {
  value = aws_api_gateway_resource.endpoint.path
}
```

---

## 🔧 Module 3 : `lambda_function` (Générique)

Module réutilisable pour créer des Lambdas.

### `modules/lambda_function/variables.tf`

```terraform
variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "source_code_path" {
  description = "Path to the Lambda ZIP file"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "iam_policy_statements" {
  description = "Additional IAM policy statements (JSON format)"
  type        = list(any)
  default     = []
}
```

### `modules/lambda_function/main.tf`

```terraform
# IAM Role
resource "aws_iam_role" "lambda" {
  name = "${var.project}-${var.function_name}-${var.environment}"

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

# CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom IAM Policy (if provided)
resource "aws_iam_role_policy" "custom" {
  count = length(var.iam_policy_statements) > 0 ? 1 : 0
  name  = "${var.function_name}-custom-policy"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = var.iam_policy_statements
  })
}

# Lambda Function
resource "aws_lambda_function" "main" {
  filename         = var.source_code_path
  function_name    = "${var.project}-${var.function_name}-${var.environment}"
  role            = aws_iam_role.lambda.arn
  handler         = var.handler
  source_code_hash = filebase64sha256(var.source_code_path)
  runtime         = var.runtime
  timeout         = var.timeout
  memory_size     = var.memory_size

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.main.function_name}"
  retention_in_days = 7
}
```

### `modules/lambda_function/outputs.tf`

```terraform
output "function_name" {
  value = aws_lambda_function.main.function_name
}

output "function_arn" {
  value = aws_lambda_function.main.arn
}

output "invoke_arn" {
  value = aws_lambda_function.main.invoke_arn
}

output "role_arn" {
  value = aws_iam_role.lambda.arn
}
```

---

## 🚀 Utilisation dans `main.tf`

Voici comment utiliser ces modules pour créer **plusieurs endpoints** avec **plusieurs Lambdas** :

```terraform
# ===========================
# 1. Créer l'API Gateway de base
# ===========================
module "api_gateway" {
  source = "../../modules/api_gateway_base"

  project                 = var.project
  environment             = var.env
  api_name                = "main-api"
  stage_name              = "prod"
  api_throttle_rate_limit = 10
  api_throttle_burst_limit = 20
  quota_limit             = 1000
}

# ===========================
# 2. Lambda pour télécharger les rapports
# ===========================
module "lambda_download_reports" {
  source = "../../modules/lambda_function"

  project             = var.project
  environment         = var.env
  function_name       = "download-reports"
  source_code_path    = "${path.module}/lambdas/download-reports/handler.zip"
  timeout             = 60
  memory_size         = 512

  environment_variables = {
    REPORTS_BUCKET = module.s3_reports.bucket_name
  }

  iam_policy_statements = [
    {
      Effect = "Allow"
      Action = ["s3:ListBucket"]
      Resource = "arn:aws:s3:::${module.s3_reports.bucket_name}"
    },
    {
      Effect = "Allow"
      Action = ["s3:GetObject"]
      Resource = "arn:aws:s3:::${module.s3_reports.bucket_name}/*"
    }
  ]
}

# Endpoint API : GET /download
module "api_endpoint_download" {
  source = "../../modules/api_gateway_endpoint"

  rest_api_id          = module.api_gateway.rest_api_id
  root_resource_id     = module.api_gateway.root_resource_id
  execution_arn        = module.api_gateway.execution_arn
  path_part            = "download"
  http_method          = "GET"
  lambda_function_name = module.lambda_download_reports.function_name
  lambda_invoke_arn    = module.lambda_download_reports.invoke_arn
  require_api_key      = true
}

# ===========================
# 3. Lambda pour lister les utilisateurs
# ===========================
module "lambda_list_users" {
  source = "../../modules/lambda_function"

  project             = var.project
  environment         = var.env
  function_name       = "list-users"
  source_code_path    = "${path.module}/lambdas/list-users/handler.zip"

  environment_variables = {
    DB_SECRET_ARN = module.database.secret_arn
  }

  iam_policy_statements = [
    {
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = module.database.secret_arn
    }
  ]
}

# Endpoint API : GET /users
module "api_endpoint_users" {
  source = "../../modules/api_gateway_endpoint"

  rest_api_id          = module.api_gateway.rest_api_id
  root_resource_id     = module.api_gateway.root_resource_id
  execution_arn        = module.api_gateway.execution_arn
  path_part            = "users"
  http_method          = "GET"
  lambda_function_name = module.lambda_list_users.function_name
  lambda_invoke_arn    = module.lambda_list_users.invoke_arn
  require_api_key      = true
}

# ===========================
# 4. Lambda pour créer un rapport
# ===========================
module "lambda_create_report" {
  source = "../../modules/lambda_function"

  project             = var.project
  environment         = var.env
  function_name       = "create-report"
  source_code_path    = "${path.module}/lambdas/create-report/handler.zip"
  timeout             = 120
  memory_size         = 1024

  environment_variables = {
    REPORTS_BUCKET = module.s3_reports.bucket_name
    DB_SECRET_ARN  = module.database.secret_arn
  }

  iam_policy_statements = [
    {
      Effect = "Allow"
      Action = ["s3:PutObject"]
      Resource = "arn:aws:s3:::${module.s3_reports.bucket_name}/*"
    },
    {
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue"]
      Resource = module.database.secret_arn
    }
  ]
}

# Endpoint API : POST /reports
module "api_endpoint_create_report" {
  source = "../../modules/api_gateway_endpoint"

  rest_api_id          = module.api_gateway.rest_api_id
  root_resource_id     = module.api_gateway.root_resource_id
  execution_arn        = module.api_gateway.execution_arn
  path_part            = "reports"
  http_method          = "POST"
  lambda_function_name = module.lambda_create_report.function_name
  lambda_invoke_arn    = module.lambda_create_report.invoke_arn
  require_api_key      = true
}

# ... Ajoutez autant de Lambdas et endpoints que nécessaire ...

# ===========================
# Outputs
# ===========================
output "api_base_url" {
  value = module.api_gateway.invoke_url
}

output "api_key" {
  value     = module.api_gateway.api_key_value
  sensitive = true
}

output "api_endpoints" {
  value = {
    download_reports = "${module.api_gateway.invoke_url}/${module.api_endpoint_download.path}"
    list_users       = "${module.api_gateway.invoke_url}/${module.api_endpoint_users.path}"
    create_report    = "${module.api_gateway.invoke_url}/${module.api_endpoint_create_report.path}"
  }
}
```

---

## 📊 Comparaison : Approche Actuelle vs Modulaire

### ✅ Approche Actuelle (Monolithique)
**Un module = Lambda + API Gateway complet**

```
modules/lambda_download_reports/
  - Lambda
  - API Gateway
  - API Key
  - Usage Plan
  - Tout dans un seul module
```

**Avantages :**
- ✅ Simple à déployer/détruire
- ✅ Tout est ensemble, facile à comprendre
- ✅ Parfait pour 1-3 endpoints

**Inconvénients :**
- ❌ Duplication si vous avez 10 Lambdas
- ❌ 10 API Gateways séparées (pas optimal)
- ❌ 10 API Keys différentes (complexe à gérer)

---

### ✅ Approche Modulaire
**Modules séparés et réutilisables**

```
modules/
  api_gateway_base/       → 1 seule API Gateway
  api_gateway_endpoint/   → Réutilisable pour chaque endpoint
  lambda_function/        → Réutilisable pour chaque Lambda
```

**Avantages :**
- ✅ Une seule API Gateway pour tous les endpoints
- ✅ Une seule API Key pour tout
- ✅ Facile d'ajouter de nouveaux endpoints
- ✅ Moins de duplication de code
- ✅ Chaque Lambda peut avoir sa propre config

**Inconvénients :**
- ❌ Plus complexe à setup initialement
- ❌ Plus de fichiers à gérer
- ❌ Nécessite plus de coordination entre modules

---

## 🎯 Recommandation

**Pour votre projet actuel :** Gardez l'approche monolithique (1 module = tout)

**Si demain vous avez ≥ 5-10 endpoints différents :** Passez à l'approche modulaire

**Seuil de décision :** 
- 1-3 endpoints → Monolithique ✅
- 4-10 endpoints → Transition possible ⚠️
- 10+ endpoints → Modulaire recommandée ✅

---

## 💡 Exemple de Migration

Si vous décidez de migrer plus tard, vous pouvez :

1. Créer les nouveaux modules génériques
2. Migrer endpoint par endpoint
3. Garder l'ancien module en parallèle
4. Supprimer l'ancien une fois la migration terminée

Pas de panique, c'est 100% compatible ! 🚀

