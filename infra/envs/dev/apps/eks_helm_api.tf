data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = "eu-west-3"
}

# Exemple placeholder : remplace par ton chart maison
resource "helm_release" "api_sensors" {
  name       = "api-sensors"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  namespace  = "default"
  values = [yamlencode({
    image = {
      registry   = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"
      repository = "api-sensors"
      tag        = var.api_image_tag
    }
  })]
}
