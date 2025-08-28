output "site_bucket_id" { value = aws_s3_bucket.site.id }
output "cloudfront_domain" { value = aws_cloudfront_distribution.cdn.domain_name }
