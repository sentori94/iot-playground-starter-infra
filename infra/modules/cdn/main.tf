# ===========================
# S3 Bucket for Static Content
# ===========================

resource "aws_s3_bucket" "cdn" {
  bucket = "${var.project}-cdn-${var.environment}"
  
  tags = merge(
    var.tags,
    {
      Name = "${var.project}-cdn-${var.environment}"
    }
  )
}

# Block public access
resource "aws_s3_bucket_public_access_block" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS configuration (optional, adjust as needed)
resource "aws_s3_bucket_cors_configuration" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ===========================
# CloudFront Origin Access Control
# ===========================

resource "aws_cloudfront_origin_access_control" "cdn" {
  name                              = "${var.project}-cdn-oac-${var.environment}"
  description                       = "OAC for ${var.project} CDN"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ===========================
# CloudFront Distribution
# ===========================

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} CDN - ${var.environment}"
  default_root_object = "index.html"
  price_class         = var.price_class

  # S3 Origin
  origin {
    domain_name              = aws_s3_bucket.cdn.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.cdn.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn.id
  }

  # Default cache behavior
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.cdn.id}"

    forwarded_values {
      query_string = false
      headers      = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Custom error responses for SPA
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Optional: Custom domain
  dynamic "aliases" {
    for_each = var.domain_name != "" ? [var.domain_name] : []
    content {
      aliases = [aliases.value]
    }
  }

  # SSL Certificate
  viewer_certificate {
    cloudfront_default_certificate = var.acm_certificate_arn == ""
    acm_certificate_arn            = var.acm_certificate_arn != "" ? var.acm_certificate_arn : null
    ssl_support_method             = var.acm_certificate_arn != "" ? "sni-only" : null
    minimum_protocol_version       = var.acm_certificate_arn != "" ? "TLSv1.2_2021" : "TLSv1"
  }

  # Geo restrictions (none by default)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project}-cdn-${var.environment}"
    }
  )
}

# ===========================
# S3 Bucket Policy for CloudFront
# ===========================

resource "aws_s3_bucket_policy" "cdn" {
  bucket = aws_s3_bucket.cdn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.cdn.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cdn]
}
