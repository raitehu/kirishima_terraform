locals {
  service_name = "garland"
}

#######################
#         ECR         #
#######################
resource "aws_ecr_repository" "default" {
  name                 = "${var.env}-${local.service_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#######################
#       Service       #
#######################
resource "aws_ecs_service" "garland" {
  name            = local.service_name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.default.arn
  desired_count   = var.env == "prd" ? 1 : 0
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  # deployment_controller {
  #   type = "CODE_DEPLOY"
  # }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.env}-${local.service_name}"
    container_port   = 3000
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      load_balancer
    ]
  }
}

#######################
#        TASK         #
#######################
resource "aws_ecs_task_definition" "default" {
  family                   = "${var.env}-${local.service_name}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  execution_role_arn = var.task_execution_role_arn
  task_role_arn      = var.task_role_arn

  container_definitions = templatefile(
    "${path.module}/container_definitions.json",
    {
      container_name        = "${var.env}-${local.service_name}"
      ecr_image_url         = aws_ecr_repository.default.repository_url
      log_group             = aws_cloudwatch_log_group.garland.name
      TABLE_NAME            = aws_dynamodb_table.default.name
      REGION                = "ap-northeast-1"
      ACCESS_KEY_ID_ARN     = aws_ssm_parameter.access_dynamodb_access_key_id.arn
      SECRET_ACCESS_KEY_ARN = aws_ssm_parameter.access_dynamodb_secret_access_key.arn
      DYNAMODB_ENDPOINT     = "http://dynamodb.ap-northeast-1.amazonaws.com"
    }
  )

  lifecycle {
    ignore_changes = [
      container_definitions,
      volume
    ]
  }
}

# TODO CodeXxxx

#######################
#      DynamoDB       #
#######################
resource "aws_dynamodb_table" "default" {
  name         = "${var.env}-${local.service_name}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "TweetURL"
  range_key    = "ExpireDate"

  attribute {
    name = "TweetURL"
    type = "S"
  }

  attribute {
    name = "ExpireDate"
    type = "S"
  }
}

resource "aws_ssm_parameter" "access_dynamodb_access_key_id" {
  name  = "/${var.env}/dynamodb_access_key_id"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "access_dynamodb_secret_access_key" {
  name  = "/${var.env}/dynamodb_secrets_access_key"
  type  = "SecureString"
  value = "dummy"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_iam_policy_document" "access_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:DescribeTable",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:ConditionCheckItem"
    ]
    resources = [aws_dynamodb_table.default.arn]
  }
}
resource "aws_iam_user_policy" "access_dynamodb" {
  name   = "${var.env}-access-garland-dynamodb"
  user   = aws_iam_user.access_dynamodb.name
  policy = data.aws_iam_policy_document.access_dynamodb.json
}
resource "aws_iam_user" "access_dynamodb" {
  name = "${var.env}-access-garland-dynamodb"
}

#######################
#         LOG         #
#######################
resource "aws_cloudwatch_log_group" "garland" {
  name              = "${var.env}-${local.service_name}"
  retention_in_days = 7
}
