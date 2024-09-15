output "bucket_id" {
  value = aws_s3_bucket.default.id
}
output "bucket_domain_name" {
  value = aws_s3_bucket.default.bucket_regional_domain_name
}
output "OAI_access_identity_path" {
  value = aws_cloudfront_origin_access_identity.default.cloudfront_access_identity_path
}
