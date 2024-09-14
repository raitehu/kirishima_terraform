locals {
  region                   = "ap-northeast-1"
  availability_zone_suffix = ["a", "c", "d"]

  cidr_block_vpc = "172.31.0.0/16"
  cidr_block_public = [
    "172.31.32.0/20",
    "172.31.0.0/20",
    "172.31.16.0/20"
  ]
  cidr_block_protected = [
    "172.31.48.0/20",
    "172.31.64.0/20",
    "172.31.80.0/20"
  ]
  cidr_block_private = [
    "172.31.96.0/20",
    "172.31.112.0/20",
    "172.31.128.0/20"
  ]

  wanderers_info = {
    backend_url = "https://wanderers-info-backend.herokuapp.com"
    tags = {
      Category = "wanderers_info"
    }
  }
}
