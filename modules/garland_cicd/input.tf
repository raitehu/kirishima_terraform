variable "env" {
  type = string
}
variable "codestar_connections_arn" {
  type = string
}
variable "artifact_store_bucket" {
  type = string
}
variable "listener_arn_active" {
  type = string
}
variable "listener_arn_standby" {
  type = string
}
variable "tg_name_blue" {
  type = string
}
variable "tg_name_green" {
  type = string
}
variable "env_ecr_image_url" {
  type = string
}
variable "env_log_group" {
  type = string
}
variable "env_table_name" {
  type = string
}
variable "env_access_key_id_arn" {
  type = string
}
variable "env_secret_access_key_arn" {
  type = string
}
variable "env_task_role_arn" {
  type = string
}
variable "env_task_execution_role_arn" {
  type = string
}
