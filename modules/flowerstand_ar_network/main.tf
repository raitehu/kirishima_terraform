resource "aws_cloudfront_distribution" "default" {
  # Origin - flowerstand AR
  origin {
    domain_name = var.s3_bucket_domain_name_flowerstand_ar
    origin_id   = var.s3_bucket_id_flowerstand_ar
    s3_origin_config {
      origin_access_identity = var.s3_OAI_path_flowerstand_ar
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = var.s3_bucket_id_flowerstand_ar

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
