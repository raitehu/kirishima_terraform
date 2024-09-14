locals {
  region                   = "ap-northeast-1"
  availability_zone_suffix = ["a", "c"]

  cidr_block_vpc = "172.31.0.0/16"
  cidr_block_public = [
    "172.31.0.0/20",
    "172.31.16.0/20"
  ]
  cidr_block_private = [
    "172.31.32.0/20",
    "172.31.48.0/20"
  ]

  wanderers_info = {
    backend_url = "https://wanderers-info-backend.herokuapp.com"
    tags = {
      Category = "wanderers_info"
    }
  }
}
