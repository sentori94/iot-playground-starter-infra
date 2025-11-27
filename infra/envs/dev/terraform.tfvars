public_subnets = ["public_a", "public_b"]
private_subnets = ["private_a", "private_b"]

env              = "dev"
project          = "iot-playground"
aws_region       = "eu-west-3"

# Tailles et coûts plus light en dev
rds_instance_class = "db.t4g.micro"
ecs_cpu            = "512"
ecs_memory         = "1024"

grafana_image_ecr = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/grafana:latest"
prom_image_ecr    = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/prometheus:latest"

image_url = "908518190934.dkr.ecr.eu-west-3.amazonaws.com/iot-playground-starter:latest"

# Route53 - Domaine personnalisé
route53_zone_name      = "iot-devices.cloud"
backend_domain_name    = "api.iot-devices.cloud"
# prometheus_domain_name = "prometheus.iot-devices.cloud"
# grafana_domain_name    = "grafana.iot-devices.cloud"

# Frontend URL pour CORS
frontend_url = "https://app.iot-devices.cloud,http://app.iot-devices.cloud"