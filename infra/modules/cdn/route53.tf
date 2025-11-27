# ===========================
# Route53 Configuration (Optional)
# ===========================

# Note: Only creates DNS records if domain_name is provided
# The hosted zone must already exist or be created separately

data "aws_route53_zone" "main" {
  count = var.domain_name != "" ? 1 : 0
  name  = var.route53_zone_name
}

resource "aws_route53_record" "cdn" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}

# Optional: IPv6 support
resource "aws_route53_record" "cdn_ipv6" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main[0].zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
