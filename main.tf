#################
#   Terraform   #
#################
module "s3_terraformbackend" {
  source = "./modules/s3"

  bucket = "cloudgate-terraform-backend"
}

##################
#     Common     #
##################
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
module "parameter_stores" {
  source = "./modules/parameter_stores"

  tags = local.wanderers_info.tags
}

#################
#     Yakan     #
#################
module "s3_yakan" {
  source = "./modules/s3_via_cloudfront"

  bucket = "yakan-static"
}

#################
#      Apps     #
#################
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

#################
#     Tools     #
#################
module "wanderers_info_tools" {
  source = "./modules/wanderers_info_tools"

  tags                       = local.wanderers_info.tags
  wanderers_info_backend_url = var.wanderers_info_backend_url
}

#################
#   フラスタAR   #
#################
# CloudFront
module "flowerstand_ar_network" {
  source = "./modules/flowerstand_ar_network"

  s3_bucket_id_yakan                   = module.s3_yakan.bucket_id
  s3_bucket_domain_name_yakan          = module.s3_yakan.bucket_domain_name
  s3_OAI_path_yakan                    = module.s3_yakan.OAI_access_identity_path
  s3_bucket_id_flowerstand_ar          = module.s3_flowerstand_ar.bucket_id
  s3_bucket_domain_name_flowerstand_ar = module.s3_flowerstand_ar.bucket_domain_name
  s3_OAI_path_flowerstand_ar           = module.s3_flowerstand_ar.OAI_access_identity_path
}
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
