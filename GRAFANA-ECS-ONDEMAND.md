# 🚀 Grafana ECS On-Demand - Guide d'Implémentation

## 📋 Concept

Un service Grafana sur ECS Fargate qui démarre **à la demande** (desired_count = 0 par défaut) avec IP publique, sans ALB.

**Coût : $0 quand éteint, ~$3-5/mois selon usage réel**

---

## 🏗️ Architecture

```
Frontend
   ↓
[Bouton "Démarrer Grafana"]
   ↓
Lambda "grafana-starter"
   ↓
aws ecs update-service --desired-count 1
   ↓
ECS Task démarre (30-60s)
   ↓
Récupère IP publique
   ↓
Frontend affiche: http://<ip>:3000
   ↓
Utilisateur accède à Grafana
   ↓
[Bouton "Arrêter Grafana"]
   ↓
Lambda "grafana-stopper"
   ↓
aws ecs update-service --desired-count 0
```

---

## 📦 Composants à Créer

### 1. Module Terraform : `grafana_on_demand`

**Fichiers :**
- `infra/modules/grafana_on_demand/main.tf`
- `infra/modules/grafana_on_demand/variables.tf`
- `infra/modules/grafana_on_demand/outputs.tf`

**Ressources :**
- ECS Task Definition (Grafana container)
- ECS Service (desired_count = 0)
- Security Group (port 3000 ouvert)
- IAM Role pour la tâche
- Lambda "grafana-controller" (start/stop/status)
- API Gateway pour appeler la Lambda depuis le frontend

### 2. Lambda Grafana Controller

**Fonctions :**
- `start` : Met desired_count = 1 et attend que l'IP soit disponible
- `stop` : Met desired_count = 0
- `status` : Retourne l'état (running/stopped) et l'IP publique si actif

---

## 🔧 Implémentation Terraform

### Module `grafana_on_demand/main.tf`

```terraform
# ===========================
# ECS Task Definition
# ===========================
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.project}-grafana-ondemand-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # 0.25 vCPU
  memory                   = "512"  # 512 MB
  execution_role_arn       = aws_iam_role.grafana_execution.arn
  task_role_arn            = aws_iam_role.grafana_task.arn

  container_definitions = jsonencode([{
    name  = "grafana"
    image = var.grafana_image
    
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    
    environment = [
      {
        name  = "GF_SERVER_ROOT_URL"
        value = "http://localhost:3000"
      },
      {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = var.grafana_admin_password
      },
      {
        name  = "GF_AUTH_ANONYMOUS_ENABLED"
        value = "false"
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "grafana"
      }
    }
  }])

  tags = var.tags
}

# ===========================
# ECS Service (desired_count = 0)
# ===========================
resource "aws_ecs_service" "grafana" {
  name            = "${var.project}-grafana-ondemand-${var.environment}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana.arn
  launch_type     = "FARGATE"
  desired_count   = 0  # 🎯 Par défaut éteint !

  network_configuration {
    subnets          = var.public_subnet_ids
    security_groups  = [aws_security_group.grafana.id]
    assign_public_ip = true  # 🎯 IP publique !
  }

  # Ignore changes to desired_count (géré par Lambda)
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = var.tags
}

# ===========================
# Security Group
# ===========================
resource "aws_security_group" "grafana" {
  name        = "${var.project}-grafana-ondemand-${var.environment}"
  description = "Security group for Grafana on-demand"
  vpc_id      = var.vpc_id

  ingress {
    description = "Grafana HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Ouvert à tous (ou restreindre à votre IP)
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ===========================
# CloudWatch Log Group
# ===========================
resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.project}-grafana-ondemand-${var.environment}"
  retention_in_days = 7

  tags = var.tags
}

# ===========================
# IAM Roles
# ===========================
resource "aws_iam_role" "grafana_execution" {
  name = "${var.project}-grafana-execution-${var.environment}"

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

resource "aws_iam_role_policy_attachment" "grafana_execution" {
  role       = aws_iam_role.grafana_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "grafana_task" {
  name = "${var.project}-grafana-task-${var.environment}"

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

# Policy pour lire CloudWatch (datasource)
resource "aws_iam_role_policy" "grafana_cloudwatch" {
  name = "${var.project}-grafana-cloudwatch-${var.environment}"
  role = aws_iam_role.grafana_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cloudwatch:DescribeAlarmsForMetric",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics"
      ]
      Resource = "*"
    }]
  })
}

# ===========================
# Lambda Controller
# ===========================
data "archive_file" "grafana_controller" {
  type        = "zip"
  source_file = "${path.module}/files/controller.py"
  output_path = "${path.module}/grafana_controller.zip"
}

resource "aws_lambda_function" "grafana_controller" {
  filename         = data.archive_file.grafana_controller.output_path
  function_name    = "${var.project}-grafana-controller-${var.environment}"
  role            = aws_iam_role.lambda_controller.arn
  handler         = "controller.lambda_handler"
  source_code_hash = data.archive_file.grafana_controller.output_base64sha256
  runtime         = "python3.11"
  timeout         = 120

  environment {
    variables = {
      CLUSTER_NAME = var.ecs_cluster_name
      SERVICE_NAME = aws_ecs_service.grafana.name
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "lambda_controller" {
  name = "${var.project}-lambda-grafana-controller-${var.environment}"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_controller_logs" {
  role       = aws_iam_role.lambda_controller.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_controller_ecs" {
  name = "${var.project}-lambda-controller-ecs-${var.environment}"
  role = aws_iam_role.lambda_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===========================
# API Gateway
# ===========================
resource "aws_api_gateway_rest_api" "grafana_controller" {
  name        = "${var.project}-grafana-controller-${var.environment}"
  description = "API pour contrôler Grafana on-demand"

  tags = var.tags
}

resource "aws_api_gateway_resource" "grafana" {
  rest_api_id = aws_api_gateway_rest_api.grafana_controller.id
  parent_id   = aws_api_gateway_rest_api.grafana_controller.root_resource_id
  path_part   = "grafana"
}

# POST /grafana (start/stop/status)
resource "aws_api_gateway_method" "grafana_post" {
  rest_api_id   = aws_api_gateway_rest_api.grafana_controller.id
  resource_id   = aws_api_gateway_resource.grafana.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "grafana_post" {
  rest_api_id = aws_api_gateway_rest_api.grafana_controller.id
  resource_id = aws_api_gateway_resource.grafana.id
  http_method = aws_api_gateway_method.grafana_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.grafana_controller.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.grafana_controller.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.grafana_controller.execution_arn}/*/*"
}

# Deployment
resource "aws_api_gateway_deployment" "grafana_controller" {
  depends_on = [aws_api_gateway_integration.grafana_post]

  rest_api_id = aws_api_gateway_rest_api.grafana_controller.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_integration.grafana_post))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "grafana_controller" {
  deployment_id = aws_api_gateway_deployment.grafana_controller.id
  rest_api_id   = aws_api_gateway_rest_api.grafana_controller.id
  stage_name    = var.environment

  tags = var.tags
}
```

---

## 🐍 Lambda Controller (`files/controller.py`)

```python
import boto3
import json
import time
import os

ecs = boto3.client('ecs')
ec2 = boto3.client('ec2')

CLUSTER_NAME = os.environ['CLUSTER_NAME']
SERVICE_NAME = os.environ['SERVICE_NAME']

def lambda_handler(event, context):
    """
    Contrôle Grafana on-demand
    Body: {"action": "start" | "stop" | "status"}
    """
    try:
        body = json.loads(event.get('body', '{}'))
        action = body.get('action', 'status')
        
        if action == 'start':
            return start_grafana()
        elif action == 'stop':
            return stop_grafana()
        elif action == 'status':
            return get_status()
        else:
            return response(400, {'error': 'Invalid action. Use: start, stop, status'})
    
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'error': str(e)})


def start_grafana():
    """Démarre Grafana (desired_count = 1)"""
    # Mettre desired_count à 1
    ecs.update_service(
        cluster=CLUSTER_NAME,
        service=SERVICE_NAME,
        desiredCount=1
    )
    
    # Attendre que la tâche démarre et récupérer l'IP (max 90 secondes)
    for i in range(18):  # 18 x 5s = 90s
        time.sleep(5)
        
        # Lister les tâches
        tasks = ecs.list_tasks(
            cluster=CLUSTER_NAME,
            serviceName=SERVICE_NAME,
            desiredStatus='RUNNING'
        )
        
        if tasks['taskArns']:
            # Décrire la tâche pour obtenir l'ENI
            task_details = ecs.describe_tasks(
                cluster=CLUSTER_NAME,
                tasks=tasks['taskArns']
            )
            
            if task_details['tasks']:
                task = task_details['tasks'][0]
                
                # Vérifier si la tâche est en RUNNING
                if task['lastStatus'] == 'RUNNING':
                    # Récupérer l'ENI
                    for attachment in task['attachments']:
                        if attachment['type'] == 'ElasticNetworkInterface':
                            for detail in attachment['details']:
                                if detail['name'] == 'networkInterfaceId':
                                    eni_id = detail['value']
                                    
                                    # Récupérer l'IP publique
                                    eni = ec2.describe_network_interfaces(
                                        NetworkInterfaceIds=[eni_id]
                                    )
                                    
                                    public_ip = eni['NetworkInterfaces'][0].get('Association', {}).get('PublicIp')
                                    
                                    if public_ip:
                                        return response(200, {
                                            'status': 'running',
                                            'message': 'Grafana started successfully',
                                            'url': f'http://{public_ip}:3000',
                                            'ip': public_ip
                                        })
    
    # Timeout
    return response(202, {
        'status': 'starting',
        'message': 'Grafana is starting. Please check status in a few seconds.'
    })


def stop_grafana():
    """Arrête Grafana (desired_count = 0)"""
    ecs.update_service(
        cluster=CLUSTER_NAME,
        service=SERVICE_NAME,
        desiredCount=0
    )
    
    return response(200, {
        'status': 'stopped',
        'message': 'Grafana stopped successfully'
    })


def get_status():
    """Retourne le statut actuel de Grafana"""
    # Décrire le service
    services = ecs.describe_services(
        cluster=CLUSTER_NAME,
        services=[SERVICE_NAME]
    )
    
    if not services['services']:
        return response(404, {'error': 'Service not found'})
    
    service = services['services'][0]
    running_count = service['runningCount']
    desired_count = service['desiredCount']
    
    if running_count == 0:
        return response(200, {
            'status': 'stopped',
            'runningCount': running_count,
            'desiredCount': desired_count
        })
    
    # Si en cours d'exécution, récupérer l'IP
    tasks = ecs.list_tasks(
        cluster=CLUSTER_NAME,
        serviceName=SERVICE_NAME,
        desiredStatus='RUNNING'
    )
    
    if tasks['taskArns']:
        task_details = ecs.describe_tasks(
            cluster=CLUSTER_NAME,
            tasks=tasks['taskArns']
        )
        
        if task_details['tasks']:
            task = task_details['tasks'][0]
            
            for attachment in task['attachments']:
                if attachment['type'] == 'ElasticNetworkInterface':
                    for detail in attachment['details']:
                        if detail['name'] == 'networkInterfaceId':
                            eni_id = detail['value']
                            eni = ec2.describe_network_interfaces(
                                NetworkInterfaceIds=[eni_id]
                            )
                            public_ip = eni['NetworkInterfaces'][0].get('Association', {}).get('PublicIp')
                            
                            return response(200, {
                                'status': 'running',
                                'runningCount': running_count,
                                'desiredCount': desired_count,
                                'url': f'http://{public_ip}:3000',
                                'ip': public_ip
                            })
    
    return response(200, {
        'status': 'starting',
        'runningCount': running_count,
        'desiredCount': desired_count
    })


def response(status_code, body):
    """Retourne une réponse HTTP avec CORS"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body)
    }
```

---

## 🎨 Intégration Frontend

```javascript
// API pour contrôler Grafana
const GRAFANA_API = "https://xxx.execute-api.eu-west-3.amazonaws.com/dev/grafana";

// Composant React
function GrafanaOnDemand() {
  const [status, setStatus] = useState('stopped');
  const [url, setUrl] = useState(null);
  const [loading, setLoading] = useState(false);

  // Vérifier le statut
  const checkStatus = async () => {
    const res = await fetch(GRAFANA_API, {
      method: 'POST',
      body: JSON.stringify({ action: 'status' })
    });
    const data = await res.json();
    setStatus(data.status);
    if (data.url) setUrl(data.url);
  };

  // Démarrer Grafana
  const startGrafana = async () => {
    setLoading(true);
    const res = await fetch(GRAFANA_API, {
      method: 'POST',
      body: JSON.stringify({ action: 'start' })
    });
    const data = await res.json();
    
    if (data.status === 'starting') {
      // Attendre et re-vérifier
      setTimeout(checkStatus, 5000);
    } else {
      setStatus(data.status);
      setUrl(data.url);
    }
    setLoading(false);
  };

  // Arrêter Grafana
  const stopGrafana = async () => {
    await fetch(GRAFANA_API, {
      method: 'POST',
      body: JSON.stringify({ action: 'stop' })
    });
    setStatus('stopped');
    setUrl(null);
  };

  return (
    <div>
      <h2>Grafana On-Demand</h2>
      <p>Status: {status}</p>
      
      {status === 'stopped' && (
        <button onClick={startGrafana} disabled={loading}>
          {loading ? 'Démarrage...' : 'Démarrer Grafana'}
        </button>
      )}
      
      {status === 'running' && url && (
        <>
          <a href={url} target="_blank">Ouvrir Grafana</a>
          <button onClick={stopGrafana}>Arrêter Grafana</button>
        </>
      )}
      
      {status === 'starting' && <p>Grafana démarre... (30-60s)</p>}
    </div>
  );
}
```

---

## 💰 Calcul de Coûts Réels

### Scénario 1 : Usage occasionnel (2h/jour)
- ECS Fargate : $0.05/heure × 2h × 30 jours = **$3/mois**
- Pas d'ALB = **$0**
- **Total : $3/mois** 🎉

### Scénario 2 : Usage modéré (4h/jour)
- ECS Fargate : $0.05/heure × 4h × 30 jours = **$6/mois**
- **Total : $6/mois**

### Scénario 3 : Always-on (24h/jour)
- ECS Fargate : $0.05/heure × 24h × 30 jours = **$36/mois**
- **Total : $36/mois** (toujours moins cher que $31 avec ALB!)

---

## ✅ Avantages de cette Solution

1. **Coût optimisé** : $0 quand éteint
2. **Pas d'ALB** : Économie de $16/mois
3. **Contrôle total** : Configuration custom, données dans VPC
4. **UX acceptable** : 30-60s de démarrage (temps pour un café ☕)
5. **Compatible multi-mode** : Fonctionne pour ECS ET Serverless
6. **Réutilise votre infra** : Même pattern que votre infra-manager

---

## 📚 Documentation Complémentaire

- Configuration Grafana avec CloudWatch datasource
- Dashboards à importer
- Script de shutdown automatique après X minutes d'inactivité
- Elastic IP (optionnel) pour IP fixe

---

**Conclusion :** C'est la meilleure solution pour votre use case ! Économique, flexible, et cohérente avec votre architecture ECS existante. 🚀

