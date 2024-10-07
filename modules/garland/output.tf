output "ecr_image_url" {
  value = aws_ecr_repository.default.repository_url
}
output "log_group" {
  value = aws_cloudwatch_log_group.garland.name
}
output "table_name" {
  value = aws_dynamodb_table.default.name
}
output "access_key_id_arn" {
  value = aws_ssm_parameter.access_dynamodb_access_key_id.arn
}
output "secret_access_key_arn" {
  value = aws_ssm_parameter.access_dynamodb_secret_access_key.arn
}
