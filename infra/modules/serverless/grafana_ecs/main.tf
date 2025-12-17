# ===========================
# ECS Task Definition Grafana Serverless
# ===========================
resource "aws_ecs_task_definition" "grafana_serverless" {
  family                   = "${var.project}-grafana-serverless-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.grafana_execution.arn
  task_role_arn            = var.grafana_task_role_arn

  container_definitions = jsonencode([{
    name  = "grafana"
    image = "${var.grafana_image_uri}:${var.grafana_image_tag}"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "GF_SERVER_ROOT_URL"
        value = "https://${var.custom_domain_name}"
      },
      {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = var.grafana_admin_password
      },
      {
        name  = "GF_AUTH_ANONYMOUS_ENABLED"
        value = "false"
      },
      {
        name  = "AWS_REGION"
        value = data.aws_region.current.name
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.grafana.name
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "grafana"
      }
    }
  }])

  tags = var.tags
}

# ===========================
# ECS Service
# ===========================
resource "aws_ecs_service" "grafana_serverless" {
  name            = "${var.project}-grafana-serverless-${var.environment}"
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.grafana_serverless.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.grafana.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]

  tags = var.tags
}

# ===========================
# Security Group Grafana
# ===========================
resource "aws_security_group" "grafana" {
  name        = "${var.project}-grafana-serverless-${var.environment}"
  description = "Security group for Grafana Serverless"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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
# Security Group ALB
# ===========================
resource "aws_security_group" "alb" {
  name        = "${var.project}-grafana-alb-${var.environment}"
  description = "Security group for Grafana ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from Internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
# Application Load Balancer
# ===========================
resource "aws_lb" "grafana" {
  name               = "grafana-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = var.tags
}

# ===========================
# Target Group
# ===========================
resource "aws_lb_target_group" "grafana" {
  name        = "grf-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200,302"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = var.tags
}

# ===========================
# HTTPS Listener (si domaine personnalisé configuré)
# ===========================
resource "aws_lb_listener" "https" {
  count = var.custom_domain_name != "" ? 1 : 0

  load_balancer_arn = aws_lb.grafana.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }

  depends_on = [aws_lb_target_group.grafana]
}

# ===========================
# HTTP Listener (forward si pas de domaine personnalisé, sinon redirect to HTTPS)
# ===========================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = var.custom_domain_name != "" ? "redirect" : "forward"

    target_group_arn = var.custom_domain_name != "" ? null : aws_lb_target_group.grafana.arn

    dynamic "redirect" {
      for_each = var.custom_domain_name != "" ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

# ===========================
# Route53 Record
# ===========================
resource "aws_route53_record" "grafana" {
  count = var.custom_domain_name != "" ? 1 : 0

  zone_id = var.route53_zone_id
  name    = var.custom_domain_name
  type    = "A"

  alias {
    name                   = aws_lb.grafana.dns_name
    zone_id                = aws_lb.grafana.zone_id
    evaluate_target_health = true
  }
}

# ===========================
# CloudWatch Log Group
# ===========================
resource "aws_cloudwatch_log_group" "grafana" {
  name              = "/ecs/${var.project}-grafana-serverless-${var.environment}"
  retention_in_days = 7

  tags = var.tags
}

# ===========================
# IAM Roles
# ===========================
resource "aws_iam_role" "grafana_execution" {
  name = "${var.project}-grafana-serverless-exec-${var.environment}"

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

# Permission pour lire les secrets (password Grafana si besoin)
resource "aws_iam_role_policy" "grafana_execution_secrets" {
  name = "${var.project}-grafana-exec-secrets-${var.environment}"
  role = aws_iam_role.grafana_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ]
      Resource = "*"
    }]
  })
}

data "aws_region" "current" {}

