# ===========================
# ECS Service Module (réutilisable)
# ===========================

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.service_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# IAM Roles
data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "exec" {
  name               = "${var.service_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Politique pour ECR (pull d'images)
resource "aws_iam_role_policy_attachment" "exec_ecr" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Politique additionnelle pour secrets
resource "aws_iam_role_policy" "exec_secrets" {
  count = length(var.secret_arns) > 0 ? 1 : 0
  name  = "${var.service_name}-exec-secrets"
  role  = aws_iam_role.exec.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.secret_arns
      }
    ]
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.service_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = var.tags
}

# Politique X-Ray pour le task role
resource "aws_iam_role_policy_attachment" "task_xray" {
  count      = var.enable_xray ? 1 : 0
  role       = aws_iam_role.task.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# CloudWatch Log Group pour X-Ray daemon
resource "aws_cloudwatch_log_group" "xray" {
  count             = var.enable_xray ? 1 : 0
  name              = "/ecs/${var.service_name}-xray"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Task Definition
resource "aws_ecs_task_definition" "this" {
  family                   = var.service_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode(concat(
    [
      {
        name      = var.service_name
        image     = var.image_url
        essential = true
        portMappings = [
          {
            containerPort = var.container_port
            hostPort      = var.container_port
            protocol      = "tcp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.this.name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = var.service_name
          }
        }
        environment = var.environment_variables
        secrets     = var.secrets
        healthCheck = var.container_health_check
      }
    ],
    var.enable_xray ? [
      {
        name      = "xray-daemon"
        image     = "public.ecr.aws/xray/aws-xray-daemon:latest"
        essential = false
        cpu       = 32
        memoryReservation = 256
        portMappings = [
          {
            containerPort = 2000
            protocol      = "udp"
          }
        ]
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = aws_cloudwatch_log_group.xray[0].name
            awslogs-region        = var.aws_region
            awslogs-stream-prefix = "xray-daemon"
          }
        }
        environment = [
          {
            name  = "AWS_REGION"
            value = var.aws_region
          }
        ]
        command = ["-o"]
      }
    ] : []
  ))

  tags = var.tags
}

# ECS Service
resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.service_name
      container_port   = var.container_port
    }
  }

  health_check_grace_period_seconds = var.target_group_arn != "" ? var.health_check_grace_period : null

  tags = var.tags
}
