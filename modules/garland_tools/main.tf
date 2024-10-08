locals {
  garland_url = var.env == "prd" ? "https://garland.raitehu.com/" : "https://garland-stg.raitehu.com/"
}

##############################
#    NEW ARRIVAL NOTIFIER    #
##############################
data "aws_s3_object" "garland_new_arrival_notifier_zip" {
  bucket = var.tools_bucket
  key    = "garland-new-arrival-notifier/lambda_function.zip"
}
resource "aws_lambda_function" "garland_new_arrival_notifier" {
  function_name = "${var.env}-garland-new-arrival-notifier"
  role          = aws_iam_role.dynamodb_stream_consumer.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 10

  layers = [
    "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SourceCode
  s3_bucket = var.tools_bucket
  s3_key    = data.aws_s3_object.garland_new_arrival_notifier_zip.key

  # Environments
  environment {
    variables = {
      ENV         = var.env
      GARLAND_URL = local.garland_url
    }
  }
}
resource "aws_cloudwatch_log_group" "garland_new_arrival_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.garland_new_arrival_notifier.function_name}"
  retention_in_days = 7
}
resource "aws_lambda_event_source_mapping" "garland_new_arrival_notifier" {
  batch_size        = 10
  event_source_arn  = var.dynamodb_stream_arn
  enabled           = true
  function_name     = aws_lambda_function.garland_new_arrival_notifier.arn
  starting_position = "TRIM_HORIZON"
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
resource "aws_iam_role" "dynamodb_stream_consumer" {
  name               = "${var.env}-dynamodb-stream-consumer-function"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_to_dynamodb_stream_consumer" {
  role       = aws_iam_role.dynamodb_stream_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "dynamodb_stream_consumer_to_dynamodb_stream_consumer" {
  role       = aws_iam_role.dynamodb_stream_consumer.name
  policy_arn = aws_iam_policy.dynamodb_stream_consumer.arn
}
resource "aws_iam_policy" "dynamodb_stream_consumer" {
  name   = "${var.env}-dynamodb-stream-consumer"
  policy = data.aws_iam_policy_document.dynamodb_stream_consumer.json
}
data "aws_iam_policy_document" "dynamodb_stream_consumer" {
  statement {
    sid    = "DynamodbStream"
    effect = "Allow"
    actions = [
      "dynamodb:GetShardIterator",
      "dynamodb:GetRecords",
      "dynamodb:ListStream",
      "dynamodb:DescribeStream"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt",
      "kms:DecryptSecureString",
      "ssm:GetParameter",
      "ssm:GetParameters"
    ]
    resources = ["*"]
  }
}

resource "aws_ssm_parameter" "twitter_api_key" {
  name  = "/${var.env}/twitter/api_key"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "twitter_api_key_secret" {
  name  = "/${var.env}/twitter/api_key_secret"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "twitter_access_token" {
  name  = "/${var.env}/twitter/access_token"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "twitter_access_token_secret" {
  name  = "/${var.env}/twitter/access_token_secret"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}
