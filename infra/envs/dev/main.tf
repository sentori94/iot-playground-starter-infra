terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
  backend "s3" {}
  # ← pas de var ici
}

provider "aws" { region = var.aws_region }

locals {
  vpc_id          = aws_vpc.this.id
}

# VPC & subnets
resource "aws_vpc" "this" {
  cidr_block           = "10.30.0.0/16"
  enable_dns_support   = true # recommandé pour ECS/ECR
  enable_dns_hostnames = true # recommandé pour résolutions DNS
  tags                 = { Name = "iot-vpc-dev" }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.30.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3a"
}

resource "aws_subnet" "public_b" {
  vpc_id                  = local.vpc_id
  cidr_block              = "10.30.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-west-3b"
}

resource "aws_subnet" "private_a" {
  vpc_id            = local.vpc_id
  cidr_block        = "10.30.10.0/24"
  availability_zone = "eu-west-3a"
  tags              = { Name = "iot-subnet-a", "kubernetes.io/role/internal-elb" = "1" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = local.vpc_id
  cidr_block        = "10.30.11.0/24"
  availability_zone = "eu-west-3b"
  tags              = { Name = "iot-subnet-b", "kubernetes.io/role/internal-elb" = "1" }
}

# ECR unique
resource "aws_ecr_repository" "backend" {
  name                 = "iot-backend"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = "iot-playground-starter", Env = "dev" }
}

# SG RDS
resource "aws_security_group" "rds" {
  vpc_id = local.vpc_id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "rds-sg" }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "rds-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags       = { Name = "rds-subnet-group" }
}

# 1) Internet Gateway
resource "aws_internet_gateway" "gateway" {
  vpc_id = local.vpc_id
  tags   = { Name = "iot-igw" }
}

# 2) Route table PUB avec route -> IGW
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = { Name = "rt-public" }
}

# 3) Associer la RT publique aux subnets PUBLICS
resource "aws_route_table_association" "pub_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "pub_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier                 = "iot-sensors-db"
  engine                     = "postgres"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20
  db_name                    = var.db_name
  username                   = var.db_username
  password                   = var.db_password
  skip_final_snapshot        = true
  db_subnet_group_name       = aws_db_subnet_group.this.name
  vpc_security_group_ids     = [aws_security_group.rds.id]
  deletion_protection        = false
  publicly_accessible        = true
  multi_az                   = false
  backup_retention_period    = 1
  auto_minor_version_upgrade = true
  tags                       = { Project = "iot-playground-starter", Env = "dev" }
}

# --- Security Groups ---
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-alb-sg"
  vpc_id = local.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "svc" {
  name   = "${var.app_name}-svc-sg"
  vpc_id = local.vpc_id
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- NAT ---
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  subnet_id     = aws_subnet.public_a.id
  allocation_id = aws_eip.nat.id
  tags = { Name = "nat-gw" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "priv_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "priv_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# --- Logs ---
resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.app_name}"
  retention_in_days = 14
}

# --- IAM (Execution + Task Role) ---
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
  name               = "${var.app_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}
resource "aws_iam_role_policy_attachment" "exec_attach" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.app_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# --- ALB ---
resource "aws_lb" "app" {
  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = local.vpc_id
  health_check {
    path                = var.health_path
    matcher             = "200-399"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    interval            = 30
    timeout             = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# --- ECS ---
resource "aws_ecs_cluster" "this" {
  name = "${var.app_name}-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.app_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name         = var.app_name
      image        = var.image_url
      essential    = true
      portMappings = [{ containerPort = var.container_port, hostPort = var.container_port, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.app.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.app_name
        }
      }
      environment = []

      healthCheck = {
        command     = ["CMD-SHELL", "curl -fsS http://localhost:8080/actuator/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_ecs_service" "app" {
  name            = "${var.app_name}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.svc.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  #ingress {
    #from_port   = 8080
    #to_port     = 8080
    #protocol    = "tcp"
    #cidr_blocks = ["0.0.0.0/0"]
  #}

  health_check_grace_period_seconds = 90
  #depends_on = [aws_lb_listener.http]
}

