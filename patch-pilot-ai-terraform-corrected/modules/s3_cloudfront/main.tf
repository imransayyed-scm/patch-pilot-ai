resource "aws_s3_bucket" "site" {
  bucket = var.site_bucket_name
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "index.html"
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${var.site_bucket_name}"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  origins {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = "s3-${aws_s3_bucket.site.id}"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${aws_s3_bucket.site.id}"
    viewer_protocol_policy = "redirect-to-https"
    compress = true
  }

  restrictions { geo_restriction { restriction_type = "none" } }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.tags
}
