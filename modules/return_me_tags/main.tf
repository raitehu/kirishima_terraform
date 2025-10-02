resource "aws_cloudfront_distribution" "default" {
  origin {
    domain_name = var.s3_bucket_domain_name_return_me_tags
    origin_id   = var.s3_bucket_id_return_me_tags
    s3_origin_config {
      origin_access_identity = var.s3_OAI_path_return_me_tags
    }
  }

  enabled             = true
  default_root_object = "index.html"


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.s3_bucket_id_return_me_tags

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  aliases = ["returnmetags.raitehu.com"]

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.acm_certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2019"
  }
}
