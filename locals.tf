locals {
  region                   = "ap-northeast-1"
  availability_zone_suffix = ["a", "c", "d"]

  cidr_block_vpc = "172.31.0.0/16"
  cidr_block_public = [
    "172.31.32.0/20",
    "172.31.0.0/20",
    "172.31.16.0/20"
  ]
}
