aws_region = "us-east-1"
project    = "iot-playground"
env        = "dev"

# Route53 - Domaine personnalisé pour CloudFront
domain_name          = "app.iot-devices.cloud"
route53_zone_name    = "iot-devices.cloud"
acm_certificate_arn  = "arn:aws:acm:us-east-1:908518190934:certificate/e640ab53-f1fc-4860-a311-00f77ca05ead"  # ⚠️ DOIT être créé dans us-east-1 pour CloudFront!
