# ===========================
# Route53 Module
# ===========================

# Data source pour récupérer la zone hébergée existante
data "aws_route53_zone" "main" {
  name = var.route53_zone_name
}

# Enregistrements A pour les ALBs
resource "aws_route53_record" "alb_records" {
  for_each = { for record in var.records : record.name => record }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = "A"

  alias {
    name                   = each.value.alb_dns_name
    zone_id                = each.value.alb_zone_id
    evaluate_target_health = each.value.evaluate_target_health
  }
}
