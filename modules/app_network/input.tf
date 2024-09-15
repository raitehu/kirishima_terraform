# 証明書
# variable "kongoh_acm_arn" {
#   type = string
# }
# variable "pleiades_union_acm_arn" {
#   type = string
# }
# sg
variable "security_group_ids" {
  type = list(string)
}
# subnet
variable "subnet_ids" {
  type = list(string)
}
