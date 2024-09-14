locals {
  service = "wanderers-info-tools"
}
#############################
#        healthcheck        #
#############################
data "aws_s3_object" "healthcheck_zip" {
  bucket = aws_s3_bucket.tools.bucket
  key    = "healthcheck/lambda_function.zip"
}
resource "aws_lambda_function" "healthcheck" {
  function_name = "${local.service}-healthcheck"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  # SourceCode
  s3_bucket = aws_s3_bucket.tools.bucket
  s3_key    = data.aws_s3_object.healthcheck_zip.key
  # Envs
  environment {
    variables = {
      WANDERERS_INFO_BACKEND_URL = var.wanderers_info_backend_url
    }
  }
}
resource "aws_cloudwatch_log_group" "healthcheck" {
  name              = "/aws/lambda/${aws_lambda_function.healthcheck.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "healthcheck" {
  name                         = "${local.service}-healthcheck"
  schedule_expression          = "cron(0,15,30,45 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.healthcheck.arn
    role_arn = aws_iam_role.event_bridge.arn
  }
}

#############################
#          tidy up          #
#############################
data "aws_s3_object" "tidy_up_zip" {
  bucket = aws_s3_bucket.tools.bucket
  key    = "tidy-up/lambda_function.zip"
}
resource "aws_lambda_function" "tidy_up" {
  function_name = "${local.service}-tidy-up"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  # SourceCode
  s3_bucket = aws_s3_bucket.tools.bucket
  s3_key    = data.aws_s3_object.tidy_up_zip.key
}
resource "aws_cloudwatch_log_group" "tidy_up" {
  name              = "/aws/lambda/${aws_lambda_function.tidy_up.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "tidy_up" {
  name                         = "${local.service}-tidy-up"
  schedule_expression          = "cron(5 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.tidy_up.arn
    role_arn = aws_iam_role.event_bridge.arn
  }
}

#############################
#       call backend        #
#############################
data "aws_s3_object" "call_backend" {
  bucket = aws_s3_bucket.tools.bucket
  key    = "call-backend/lambda_function.zip"
}
resource "aws_lambda_function" "call_backend" {
  function_name = "${local.service}-call-backend"
  role          = aws_iam_role.lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  # SourceCode
  s3_bucket = aws_s3_bucket.tools.bucket
  s3_key    = data.aws_s3_object.call_backend.key
  # Envs
  environment {
    variables = {
      WANDERERS_INFO_BACKEND_URL = var.wanderers_info_backend_url
    }
  }
}
resource "aws_cloudwatch_log_group" "call_backend" {
  name              = "/aws/lambda/${aws_lambda_function.call_backend.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "garland_daily" {
  name                         = "${local.service}-garland-daily"
  schedule_expression          = "cron(30 7 ? * MON,FRI *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.call_backend.arn
    role_arn = aws_iam_role.event_bridge.arn
    input = jsonencode({
      function = "/v1/garland/daily/"
    })
  }
}
resource "aws_scheduler_schedule" "garland_soon_expiry" {
  name                         = "${local.service}-garland-soon-expiry"
  schedule_expression          = "cron(15 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.call_backend.arn
    role_arn = aws_iam_role.event_bridge.arn
    input = jsonencode({
      function = "/v1/garland/soon-expiry/"
    })
  }
}
resource "aws_scheduler_schedule" "wiki_update_notify" {
  name                         = "${local.service}-wiki-update-notify"
  schedule_expression          = "cron(0 7 * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }
  target {
    arn      = aws_lambda_function.call_backend.arn
    role_arn = aws_iam_role.event_bridge.arn
    input = jsonencode({
      function = "/v1/wiki/update-notify/"
    })
  }
}

#############################
#          common           #
#############################
resource "aws_s3_bucket" "tools" {
  bucket = local.service

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "tools" {
  bucket = aws_s3_bucket.tools.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "access_parameter_store" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "access_parameter_store" {
  name   = "access-parameter-store"
  policy = data.aws_iam_policy_document.access_parameter_store.json
}
resource "aws_iam_role" "lambda" {
  name               = "${local.service}-function"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_access_parameter_store" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.access_parameter_store.arn
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
data "aws_iam_policy_document" "event_bridge_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "invoke_tools" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.healthcheck.arn,
      aws_lambda_function.tidy_up.arn,
      aws_lambda_function.call_backend.arn,
    ]
  }
}
resource "aws_iam_policy" "invoke_tools" {
  name   = "invoke-${local.service}-function"
  policy = data.aws_iam_policy_document.invoke_tools.json
}
resource "aws_iam_role" "event_bridge" {
  name               = "${local.service}-event-bridge"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_assume_role.json
}
resource "aws_iam_role_policy_attachment" "invoke_tooles" {
  role       = aws_iam_role.event_bridge.name
  policy_arn = aws_iam_policy.invoke_tools.arn
}

#############################
#           CI/CD           #
#############################
# OIDC
data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.github_actions.certificates[*].sha1_fingerprint
}

# IAM
data "aws_iam_policy_document" "oidc_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:raitehu/wanderers_info_tools:*"]
    }
  }
}
data "aws_iam_policy_document" "deploy_tools" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
      "s3:DeleteObject"
    ]
    resources = [
      aws_s3_bucket.tools.arn,
      "${aws_s3_bucket.tools.arn}/*"
    ]
  }
}
resource "aws_iam_policy" "deploy_tools" {
  name   = "deploy-${local.service}"
  policy = data.aws_iam_policy_document.deploy_tools.json
}
resource "aws_iam_role" "deploy_tools" {
  name               = "deploy-wanderers-info-tools"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume_role.json
}
resource "aws_iam_role_policy_attachment" "deploy_tools" {
  role       = aws_iam_role.deploy_tools.name
  policy_arn = aws_iam_policy.deploy_tools.arn
}
