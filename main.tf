################
#   Networks   #
################
# VPC
resource "aws_vpc" "cloudgate" {
  cidr_block = local.cidr_block_vpc
  tags = {
    Name = "vpc_cloudgate"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = 3

  vpc_id            = aws_vpc.cloudgate.id
  cidr_block        = local.cidr_block_public[count.index]
  availability_zone = "${local.region}${local.availability_zone_suffix[count.index]}"
  tags = {
    Name = "sub_public_${local.availability_zone_suffix[count.index]}"
  }
}

# Security Groups
resource "aws_security_group" "default" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = aws_vpc.cloudgate.id

  ingress = []
  egress  = []
}

# Route 53
# Kongoh
resource "aws_route53_zone" "kongoh" {
  name = "kongoh.xyz"
}
resource "aws_route53_record" "kongoh_A" {
  zone_id = aws_route53_zone.kongoh.zone_id
  name    = "*.kongoh.xyz"
  type    = "A"
  ttl     = "300"
  records = [var.on_premises_ip]
}
# pleiades-union
resource "aws_route53_zone" "pleiades" {
  name = "pleiades-union.com"
}
resource "aws_route53_record" "pleiades_union_A" {
  zone_id = aws_route53_zone.pleiades.zone_id
  name    = "*.pleiades-union.com"
  type    = "A"
  ttl     = "300"
  records = [var.on_premises_ip]
}

# CloudFront
resource "aws_cloudfront_distribution" "cloudgate" {
  # Origin - yakan
  origin {
    domain_name = aws_s3_bucket.yakan.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.yakan.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.yakan.cloudfront_access_identity_path
    }
  }
  # Origin - flowerstand AR
  origin {
    domain_name = aws_s3_bucket.flowerstand_ar.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.flowerstand_ar.id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.flowerstand_ar.cloudfront_access_identity_path
    }
  }

  # Origin - app ALB
  # TODO

  enabled             = true
  default_root_object = "index.html"

  ordered_cache_behavior {
    path_pattern     = "/flowerstand-ar*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.flowerstand_ar.id

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

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.yakan.id

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

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
resource "aws_cloudfront_origin_access_identity" "yakan" {}
resource "aws_cloudfront_origin_access_identity" "flowerstand_ar" {}

#################
#   フラスタAR   #
#################
resource "aws_s3_bucket" "flowerstand_ar" {
  bucket = "raitehu-flowerstand-ar"
}
resource "aws_s3_bucket_website_configuration" "flowerstand_ar" {
  bucket = aws_s3_bucket.flowerstand_ar.id

  index_document {
    suffix = "index.html"
  }
}
resource "aws_s3_bucket_public_access_block" "flowerstand_ar" {
  bucket = aws_s3_bucket.flowerstand_ar.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "flowerstand_ar" {
  bucket = aws_s3_bucket.flowerstand_ar.id
  policy = data.aws_iam_policy_document.flowerstand_ar.json
}
data "aws_iam_policy_document" "flowerstand_ar" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.flowerstand_ar.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.flowerstand_ar.arn}/*"
    ]
  }
}

#################
#     Yakan     #
#################
resource "aws_s3_bucket" "yakan" {
  bucket = "yakan-static"
}
resource "aws_s3_bucket_website_configuration" "yakan" {
  bucket = aws_s3_bucket.yakan.id

  index_document {
    suffix = "index.html"
  }
}
resource "aws_s3_bucket_public_access_block" "yakan" {
  bucket = aws_s3_bucket.yakan.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "yakan" {
  bucket = aws_s3_bucket.yakan.id
  policy = data.aws_iam_policy_document.yakan.json
}
data "aws_iam_policy_document" "yakan" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.yakan.iam_arn]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.yakan.arn}/*"
    ]
  }
}

#################
#   Terraform   #
#################
resource "aws_s3_bucket" "terraform_backend" {
  bucket = "cloudgate-terraform-backend"
}

resource "aws_s3_bucket_public_access_block" "terraform_backend_block_public_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
