resource "aws_ecr_repository" "repos" {
  for_each = toset(var.repositories)
  name                 = each.value
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration { scan_on_push = true }
  tags = { Project = "iot-playground-starter", Env = "dev" }
}

resource "aws_ecr_lifecycle_policy" "gc" {
  for_each   = aws_ecr_repository.repos
  repository = each.value.name
  policy     = jsonencode({
    rules = [{
      rulePriority = 1,
      description  = "Expire untagged images older than 14 days",
      selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 14 },
      action       = { type = "expire" }
    }]
  })
}
