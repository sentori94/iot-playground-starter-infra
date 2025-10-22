# ===========================
# ECS Cluster Module
# ===========================

resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = var.tags
}

