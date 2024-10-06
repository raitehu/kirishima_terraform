variable "env" {
  type    = string
  default = "prd"
}
variable "cluster_id" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}
variable "target_group_arn" {
  type = string
}
variable "task_execution_role_arn" {
  type = string
}
variable "task_role_arn" {
  type = string
}
