project     = "iot-playground"
env         = "serverless-dev"
aws_region  = "eu-west-3"

# Route53 - Domaine personnalisé pour Lambda API
route53_zone_name      = "sentori-studio.com"
lambda_api_domain_name = "api-lambda-iot.sentori-studio.com"

# Grafana - URL de base pour les dashboards
grafana_domain_name = "grafana-lambda-iot.sentori-studio.com"
grafana_url         = "http://localhost:3000"  # Sera mis à jour avec l'URL ALB Grafana après déploiement

# Grafana ECS - Configuration
enable_grafana         = false  # true pour déployer Grafana
vpc_cidr               = "10.1.0.0/16"
availability_zones     = ["eu-west-3a", "eu-west-3b"]
grafana_image_uri      = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-grafana-serverless"
grafana_image_tag      = "latest"
grafana_admin_password = "ChangeMe123!"  # TODO: Changer !

