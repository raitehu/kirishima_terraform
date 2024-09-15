#################
#   Terraform   #
#################
module "s3_terraformbackend" {
  source = "./modules/s3"

  bucket = "cloudgate-terraform-backend"
}

#################
#      VPC      #
#################
module "vpc" {
  source = "./modules/vpc"

  region                   = local.region
  cidr_block_vpc           = local.cidr_block_vpc
  cidr_block_public        = local.cidr_block_public
  cidr_block_private       = local.cidr_block_private
  availability_zone_suffix = local.availability_zone_suffix
}

module "route53" {
  source = "./modules/route53"

  on_premises_ip = var.on_premises_ip
}

# CloudFront
resource "aws_cloudfront_distribution" "cloudgate" {
  # Origin - yakan
  origin {
    domain_name = module.s3_yakan.bucket_domain_name
    origin_id   = module.s3_yakan.bucket_id
    s3_origin_config {
      origin_access_identity = module.s3_yakan.OAI_access_identity_path
    }
  }
  # Origin - flowerstand AR
  origin {
    domain_name = module.s3_flowerstand_ar.bucket_domain_name
    origin_id   = module.s3_flowerstand_ar.bucket_id
    s3_origin_config {
      origin_access_identity = module.s3_flowerstand_ar.OAI_access_identity_path
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
    target_origin_id = module.s3_flowerstand_ar.bucket_id

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

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = module.s3_yakan.bucket_id

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

#################
#   フラスタAR   #
#################
module "s3_flowerstand_ar" {
  source = "./modules/s3_via_cloudfront"

  bucket = "raitehu-flowerstand-ar"
}
module "flowerstand_ar_developers" {
  source = "./modules/s3_upload_users"

  user_names = [
    "Tsurara",
    "Pon"
  ]
}

#################
#     Yakan     #
#################
module "s3_yakan" {
  source = "./modules/s3_via_cloudfront"

  bucket = "yakan-static"
}

module "parameter_stores" {
  source = "./modules/parameter_stores"

  tags = local.wanderers_info.tags
}

module "wanderers_info_tools" {
  source = "./modules/wanderers_info_tools"

  tags                       = local.wanderers_info.tags
  wanderers_info_backend_url = var.wanderers_info_backend_url
}

module "app_network" {
  source = "./modules/app_network"

  subnet_ids = [
    module.vpc.subnet_public_a_id,
    module.vpc.subnet_private_c_id
  ]
  security_group_ids = [
    module.vpc.sg_elb_id
  ]
}

module "app_server" {
  source = "./modules/app_server"

  subnet_id = module.vpc.subnet_public_a_id
  security_group_ids = [
    module.vpc.sg_ssh_id,
    module.vpc.sg_elb_id
  ]
}
