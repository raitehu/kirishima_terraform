locals {
  service = "wanderers-info-tools"
}
#############################
#        healthcheck        #
#############################
# TODO: Lambda
# TODO: CloudWatch Logs
# TODO: EventBridge

#############################
#          tidy up          #
#############################

#############################
#        soon expiry        #
#############################

#############################
#    wiki update notify     #
#############################

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
