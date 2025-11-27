output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.cdn.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cdn.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_domain_name
}

output "cloudfront_url" {
  description = "URL of the CloudFront distribution"
  value       = module.cdn.cloudfront_url
}
