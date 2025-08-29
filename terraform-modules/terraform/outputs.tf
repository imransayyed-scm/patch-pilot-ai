output "api_gateway_endpoint" {
  description = "The invocation URL for the backend API Gateway."
  value       = module.api_gateway.api_endpoint
}

output "frontend_s3_bucket_id" {
  description = "The ID of the S3 bucket hosting the frontend static files."
  value       = module.frontend.s3_bucket_id
}

output "frontend_cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution for cache invalidation."
  value       = module.frontend.cloudfront_distribution_id
}

output "frontend_website_url" {
  description = "The public URL for the Patch Pilot AI website."
  value       = "https://${module.frontend.cloudfront_distribution_domain}"
}