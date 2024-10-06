locals {
  service_name = "garland"
}

# Task execution role
resource "aws_iam_role" "task_execution" {
  name               = "${local.service_name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume_role_policy.json
}
data "aws_iam_policy_document" "task_execution_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "task_execution" {
  name   = "${local.service_name}-task-execution"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_inline_policy.json
}
data "aws_iam_policy_document" "task_execution_inline_policy" {
  statement {
    sid = "ECS"
    actions = [
      "ecs:DescribeTaskDefinition",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "ECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "SecretsManager"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CloudWatch"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "SSM"
    actions = [
      "ssm:GetParameters",
      "kms:Decrypt"
    ]
    resources = [
      "*",
    ]
  }
}

# Task role
resource "aws_iam_role" "task" {
  name               = "${local.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
}
data "aws_iam_policy_document" "task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "task" {
  name   = "${local.service_name}-task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_inline_policy.json
}
data "aws_iam_policy_document" "task_inline_policy" {
  statement {
    sid = "DynamoDB"
    actions = [
      "dynamodb:PutItem",
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
}
