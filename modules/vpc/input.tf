variable "region" {
  type = string
}
variable "cidr_block_vpc" {
  type = string
}
variable "cidr_block_public" {
  type = list(string)
}
variable "cidr_block_protected" {
  type = list(string)
}
variable "cidr_block_private" {
  type = list(string)
}
variable "availability_zone_suffix" {
  type = list(string)
}
