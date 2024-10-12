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
  timeout       = 30

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

#########################
#    REPORT NOTIFIER    #
#########################
data "aws_s3_object" "garland_report_notifier_zip" {
  bucket = var.tools_bucket
  key    = "garland-report-notifier/lambda_function.zip"
}
resource "aws_lambda_function" "garland_report_notifier" {
  function_name = "${var.env}-garland-report-notifier"
  role          = aws_iam_role.garland_report_notifier.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  layers = [
    "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SourceCode
  s3_bucket = var.tools_bucket
  s3_key    = data.aws_s3_object.garland_report_notifier_zip.key

  # Environments
  environment {
    variables = {
      ENV               = var.env
      TABLE_NAME        = var.dynamodb_table_name
      REGION            = "ap-northeast-1"
      DYNAMODB_ENDPOINT = "http://dynamodb.ap-northeast-1.amazonaws.com"
      GARLAND_URL       = local.garland_url
    }
  }
}
resource "aws_cloudwatch_log_group" "garland_report_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.garland_report_notifier.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "garland_report_notifier" {
  name                         = "${var.env}-garland-report-notifier"
  schedule_expression          = "cron(30 7 ? * MON,FRI *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.garland_report_notifier.arn
    role_arn = aws_iam_role.event_bridge.arn
  }

  lifecycle {
    ignore_changes = [state]
  }
}

##########################
#    EXPIRED NOTIFIER    #
##########################
data "aws_s3_object" "garland_expired_notifier_zip" {
  bucket = var.tools_bucket
  key    = "garland-expired-notifier/lambda_function.zip"
}
resource "aws_lambda_function" "garland_expired_notifier" {
  function_name = "${var.env}-garland-expired-notifier"
  role          = aws_iam_role.garland_report_notifier.arn # ここは共通でOK
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  layers = [
    "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SourceCode
  s3_bucket = var.tools_bucket
  s3_key    = data.aws_s3_object.garland_expired_notifier_zip.key

  # Environments
  environment {
    variables = {
      ENV               = var.env
      TABLE_NAME        = var.dynamodb_table_name
      REGION            = "ap-northeast-1"
      DYNAMODB_ENDPOINT = "http://dynamodb.ap-northeast-1.amazonaws.com"
      GARLAND_URL       = local.garland_url
    }
  }
}
resource "aws_cloudwatch_log_group" "garland_expired_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.garland_expired_notifier.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "garland_expired_notifier" {
  name                         = "${var.env}-garland-expired-notifier"
  schedule_expression          = "cron(15 * * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.garland_expired_notifier.arn
    role_arn = aws_iam_role.event_bridge.arn
  }

  lifecycle {
    ignore_changes = [state]
  }
}

##############################
#    WIKI UPDATE NOTIFIER    #
##############################
data "aws_s3_object" "wiki_update_notifier_zip" {
  bucket = var.tools_bucket
  key    = "wiki-update-notifier/lambda_function.zip"
}
resource "aws_lambda_function" "wiki_update_notifier" {
  function_name = "${var.env}-wiki-update-notifier"
  role          = aws_iam_role.garland_report_notifier.arn # ここは共通でOK
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  layers = [
    "arn:aws:lambda:ap-northeast-1:133490724326:layer:AWS-Parameters-and-Secrets-Lambda-Extension:12"
  ]

  # SourceCode
  s3_bucket = var.tools_bucket
  s3_key    = data.aws_s3_object.wiki_update_notifier_zip.key

  # Environments
  environment {
    variables = {
      ENV           = var.env
      REGION        = "ap-northeast-1"
      WIKI_ROOT_URL = "https://seesaawiki.jp/valis/"
    }
  }
}
resource "aws_cloudwatch_log_group" "wiki_update_notifier" {
  name              = "/aws/lambda/${aws_lambda_function.wiki_update_notifier.function_name}"
  retention_in_days = 7
}
resource "aws_scheduler_schedule" "wiki_update_notifier" {
  name                         = "${var.env}-wiki-update-notifier"
  schedule_expression          = "cron(0 7 * * ? *)"
  schedule_expression_timezone = "Asia/Tokyo"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.wiki_update_notifier.arn
    role_arn = aws_iam_role.event_bridge.arn
  }

  lifecycle {
    ignore_changes = [state]
  }
}

#############
#    IAM    #
#############
# Common
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

# New Arrival Notifier
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

# Report Notifier
resource "aws_iam_role" "garland_report_notifier" {
  name               = "${var.env}-garland-report-notifier-function"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}
resource "aws_iam_role_policy_attachment" "lambda_basic_execution_to_garland_report_notifier" {
  role       = aws_iam_role.garland_report_notifier.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "garland_report_notifier" {
  role       = aws_iam_role.garland_report_notifier.name
  policy_arn = aws_iam_policy.garland_report_notifier.arn
}
resource "aws_iam_policy" "garland_report_notifier" {
  name   = "${var.env}-garland-report-notifier"
  policy = data.aws_iam_policy_document.garland_report_notifier.json
}
data "aws_iam_policy_document" "garland_report_notifier" {
  statement {
    sid = "DynamoDB"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:DescribeTable",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:ConditionCheckItem"
    ]
    resources = [
      "*"
    ]
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

# EventBridge
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
resource "aws_iam_role" "event_bridge" {
  name               = "${var.env}-garland-event-bridge"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_assume_role.json
}
resource "aws_iam_role_policy_attachment" "invoke_tools" {
  role       = aws_iam_role.event_bridge.name
  policy_arn = aws_iam_policy.invoke_tools.arn
}
resource "aws_iam_policy" "invoke_tools" {
  name   = "${var.env}-garland-invoke-tools"
  policy = data.aws_iam_policy_document.invoke_tools.json
}
data "aws_iam_policy_document" "invoke_tools" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.garland_report_notifier.arn,
      aws_lambda_function.garland_expired_notifier.arn,
      aws_lambda_function.wiki_update_notifier.arn,
    ]
  }
}

#########################
#    Parameter Store    #
#########################

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
