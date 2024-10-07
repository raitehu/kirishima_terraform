resource "aws_ssm_parameter" "wanderers_info_backend_token" {
  name  = "wanderers_info_backend_token"
  type  = "SecureString"
  value = "dummy"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "garland_backend_url" {
  name  = "garland_backend_url"
  type  = "SecureString"
  value = "dummy"

  tags = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dockerhub_user" {
  name  = "dockerhub-user"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dockerhub_token" {
  name  = "dockerhub-token"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
