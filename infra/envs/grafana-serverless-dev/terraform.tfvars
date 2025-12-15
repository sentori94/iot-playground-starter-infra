project     = "iot-playground"
env         = "grafana-serverless-dev"
aws_region  = "eu-west-3"

# Route53
route53_zone_name   = "sentori-studio.com"
grafana_domain_name = "grafana-lambda-iot.sentori-studio.com"

# Network - VPC créé automatiquement
vpc_cidr           = "10.1.0.0/16"
availability_zones = ["eu-west-3a", "eu-west-3b"]

# Grafana
grafana_image_uri      = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless"
grafana_image_tag      = "latest"
grafana_admin_password = "ChangeMe123!"  # TODO: Changer !

