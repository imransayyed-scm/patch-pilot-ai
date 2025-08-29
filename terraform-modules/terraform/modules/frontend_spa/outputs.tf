output "s3_bucket_id" { value = aws_s3_bucket.this.id }
output "cloudfront_distribution_id" { value = aws_cloudfront_distribution.this.id }
output "cloudfront_distribution_domain" { value = aws_cloudfront_distribution.this.domain_name }