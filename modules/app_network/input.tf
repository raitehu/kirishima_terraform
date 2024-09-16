# 証明書
variable "kongoh_acm_arn" {
  type = string
}
variable "pleiades_union_acm_arn" {
  type = string
}
# sg
variable "security_group_ids" {
  type = list(string)
}
# subnet
variable "vpc_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "alb_log_bucket_id" {
  type = string
}
variable "app_server_id" {
  type = string
}
