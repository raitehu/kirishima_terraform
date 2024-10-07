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

  web_front_alb_dns_name    = module.app_network.web_front_alb_dns_name
  web_front_alb_zone_id     = module.app_network.web_front_alb_zone_id
  cloudfront_yakan_dns_name = module.yakan_network.cloudfront_dns_name
  cloudfront_yakan_zone_id  = module.yakan_network.cloudfront_zone_id
}
module "parameter_stores" {
  source = "./modules/parameter_stores"

  tags = local.wanderers_info.tags
}
module "alb_logs" {
  source = "./modules/s3"

  bucket = "raitehu-alb-logs"
}
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = module.alb_logs.bucket_id
  policy = data.aws_iam_policy_document.alb_logs.json
}
data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      # アカウントIDは対応するリージョンのELBのもの
      # ap-northeast-1のELBは582318560864
      identifiers = ["arn:aws:iam::582318560864:root"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["${module.alb_logs.bucket_arn}/*"]
  }
}
resource "aws_ecs_cluster" "prd" {
  name = "prd"
}
resource "aws_ecs_cluster" "stg" {
  name = "stg"
}
resource "aws_codestarconnections_connection" "github" {
  name          = "github"
  provider_type = "GitHub"
}
module "artifact_store" {
  source = "./modules/s3"

  bucket = "raitehu-artifact-store"
}

#################
#     Yakan     #
#################
module "yakan_network" {
  source = "./modules/yakan_network"

  s3_bucket_id_yakan          = module.s3_yakan.bucket_id
  s3_bucket_domain_name_yakan = module.s3_yakan.bucket_domain_name
  s3_OAI_path_yakan           = module.s3_yakan.OAI_access_identity_path
  acm_certificate_arn         = var.kongoh_acm_arn_in_us
}
module "s3_yakan" {
  source = "./modules/s3_via_cloudfront"

  bucket = "yakan-static"
}

#################
#      Apps     #
#################
module "app_network" {
  source = "./modules/app_network"

  # 証明書
  kongoh_acm_arn         = var.kongoh_acm_arn
  pleiades_union_acm_arn = var.pleiades_union_acm_arn
  raitehu_acm_arn        = var.raitehu_acm_arn

  vpc_id = module.vpc.vpc_id
  subnet_ids = [
    module.vpc.subnet_public_a_id,
    module.vpc.subnet_public_c_id
  ]
  security_group_ids = [
    module.vpc.sg_elb_id
  ]
  alb_log_bucket_id = module.alb_logs.bucket_id
  app_server_id     = module.app_server.app_server_id
}

module "app_server" {
  source = "./modules/app_server"

  subnet_id = module.vpc.subnet_public_a_id
  security_group_ids = [
    module.vpc.sg_ssh_id,
    module.vpc.sg_elb_id
  ]
}

module "garland_iam" {
  source = "./modules/garland_iam"
}
module "prd-garland" {
  source = "./modules/garland"

  env                     = "prd"
  cluster_id              = aws_ecs_cluster.prd.id
  subnet_ids              = [module.vpc.subnet_public_a_id, module.vpc.subnet_public_c_id]
  security_group_ids      = [module.vpc.sg_elb_id]
  target_group_arn        = module.app_network.tg_arn_garland_prd
  task_execution_role_arn = module.garland_iam.task_execution_role_arn
  task_role_arn           = module.garland_iam.task_role_arn
}
module "stg-garland" {
  source = "./modules/garland"

  env                     = "stg"
  cluster_id              = aws_ecs_cluster.stg.id
  subnet_ids              = [module.vpc.subnet_public_a_id, module.vpc.subnet_public_c_id]
  security_group_ids      = [module.vpc.sg_elb_id]
  target_group_arn        = module.app_network.tg_arn_garland_stg
  task_execution_role_arn = module.garland_iam.task_execution_role_arn
  task_role_arn           = module.garland_iam.task_role_arn
}
module "prd-garland-cicd" {
  source = "./modules/garland_cicd"

  env                         = "prd"
  codestar_connections_arn    = aws_codestarconnections_connection.github.arn
  artifact_store_bucket       = module.artifact_store.bucket
  listener_arn_active         = module.app_network.listener_arn_https
  listener_arn_standby        = module.app_network.listener_arn_https_standby
  tg_name_blue                = module.app_network.tg_name_garland_prd_blue
  tg_name_green               = module.app_network.tg_name_garland_prd_green
  env_ecr_image_url           = module.prd-garland.ecr_image_url
  env_log_group               = module.prd-garland.log_group
  env_table_name              = module.prd-garland.table_name
  env_access_key_id_arn       = module.prd-garland.access_key_id_arn
  env_secret_access_key_arn   = module.prd-garland.secret_access_key_arn
  env_task_role_arn           = module.garland_iam.task_role_arn
  env_task_execution_role_arn = module.garland_iam.task_execution_role_arn
}
module "stg-garland-cicd" {
  source = "./modules/garland_cicd"

  env                         = "stg"
  codestar_connections_arn    = aws_codestarconnections_connection.github.arn
  artifact_store_bucket       = module.artifact_store.bucket
  listener_arn_active         = module.app_network.listener_arn_https
  listener_arn_standby        = module.app_network.listener_arn_https_standby
  tg_name_blue                = module.app_network.tg_name_garland_stg_blue
  tg_name_green               = module.app_network.tg_name_garland_stg_green
  env_ecr_image_url           = module.stg-garland.ecr_image_url
  env_log_group               = module.stg-garland.log_group
  env_table_name              = module.stg-garland.table_name
  env_access_key_id_arn       = module.stg-garland.access_key_id_arn
  env_secret_access_key_arn   = module.stg-garland.secret_access_key_arn
  env_task_role_arn           = module.garland_iam.task_role_arn
  env_task_execution_role_arn = module.garland_iam.task_execution_role_arn
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
