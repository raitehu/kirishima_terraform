locals {
  service_name  = "garland"
  repository_id = "raitehu/wanderers_info_garland"
  branch        = var.env == "prd" ? "main" : "staging"
}

#######################
#     CodePipeline    #
#######################
resource "aws_codepipeline" "default" {
  name     = "${var.env}-${local.service_name}"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = var.artifact_store_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = 1
      output_artifacts = ["${var.env}_garland_source"]
      configuration = {
        ConnectionArn        = var.codestar_connections_arn
        FullRepositoryId     = local.repository_id
        BranchName           = local.branch
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = 1
      input_artifacts  = ["${var.env}_garland_source"]
      output_artifacts = ["${var.env}_garland_build"]
      configuration = {
        ProjectName = aws_codebuild_project.default.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      version         = 1
      run_order       = 1
      input_artifacts = ["${var.env}_garland_build"]
      configuration = {
        ApplicationName                = aws_codedeploy_app.default.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.default.deployment_group_name
        TaskDefinitionTemplateArtifact = "${var.env}_garland_build"
        TaskDefinitionTemplatePath     = "taskdef.json"
        AppSpecTemplateArtifact        = "${var.env}_garland_build"
        AppSpecTemplatePath            = "appspec.yml"
        Image1ArtifactName             = "${var.env}_garland_build"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }
  }
}

#######################
#      CodeBuild      #
#######################
resource "aws_codebuild_project" "default" {
  name         = "${var.env}-${local.service_name}"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec.yml"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    type                        = "LINUX_CONTAINER"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "ENV"
      value = var.env
    }
    environment_variable {
      name  = "LOG_GROUP"
      value = var.env_log_group
    }
    environment_variable {
      name  = "TABLE_NAME"
      value = var.env_table_name
    }
    environment_variable {
      name  = "ACCESS_KEY_ID_ARN"
      value = var.env_access_key_id_arn
    }
    environment_variable {
      name  = "SECRET_ACCESS_KEY_ARN"
      value = var.env_secret_access_key_arn
    }
    environment_variable {
      name  = "TASK_ROLE_ARN"
      value = var.env_task_role_arn
    }
    environment_variable {
      name  = "TASK_EXECUTION_ROLE_ARN"
      value = var.env_task_execution_role_arn
    }
  }
}

#######################
#      CodeDeploy     #
#######################
resource "aws_codedeploy_app" "default" {
  name             = "${var.env}-${local.service_name}"
  compute_platform = "ECS"
}
resource "aws_codedeploy_deployment_group" "default" {
  deployment_group_name  = "${var.env}-${local.service_name}-deploy"
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"
  app_name               = aws_codedeploy_app.default.name
  service_role_arn       = aws_iam_role.codedeploy.arn

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout    = "STOP_DEPLOYMENT"
      wait_time_in_minutes = 10
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 10
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = var.env
    service_name = local.service_name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.listener_arn_active]
      }
      test_traffic_route {
        listener_arns = [var.listener_arn_standby]
      }
      target_group {
        name = var.tg_name_blue
      }
      target_group {
        name = var.tg_name_green
      }
    }
  }
}

#######################
#         IAM         #
#######################
# CodePipeline
resource "aws_iam_role" "codepipeline" {
  name               = "${var.env}-${local.service_name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role_policy.json
}
data "aws_iam_policy_document" "codepipeline_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "codepipeline" {
  name   = "${var.env}-${local.service_name}-codepipeline"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_inline_policy.json
}
data "aws_iam_policy_document" "codepipeline_inline_policy" {
  statement {
    sid = "IAM"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
  }
  statement {
    sid = "S3"
    actions = [
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetObject",
      "s3:GetBucketVersioning",
    ]
    resources = [
      "*",
    ]
  }
  statement {
    sid = "ECS"
    actions = [
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CodeBuild"
    actions = [
      "codebuild:StartBuild",
      "codebuild:BatchGetBuilds",
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CodeDeploy"
    actions = [
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetApplication",
      "codedeploy:CreateDeployment",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CodeStar"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [
      "*"
    ]
  }
}
# CodeBuild
resource "aws_iam_role" "codebuild" {
  name               = "${var.env}-${local.service_name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role_policy.json
}
data "aws_iam_policy_document" "codebuild_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.env}-${local.service_name}-codebuild"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_inline_policy.json
}
data "aws_iam_policy_document" "codebuild_inline_policy" {
  statement {
    sid = "S3"
    actions = [
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:GetBucketAcl",
      "s3:ListBucket",
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
    sid = "EC2"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
      "ec2:CreateNetworkInterfacePermission",
    ]
    resources = [
      "*"
    ]
  }
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
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeRepositories",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
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
    sid = "CodeBuild"
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "CodeStar"
    actions = [
      "codestar-connections:UseConnection",
    ]
    resources = [
      "*"
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
# CodeDeploy
resource "aws_iam_role" "codedeploy" {
  name               = "${var.env}-${local.service_name}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role_policy.json
}
data "aws_iam_policy_document" "codedeploy_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "codedeploy" {
  name   = "${var.env}-${local.service_name}-codedeploy"
  role   = aws_iam_role.codedeploy.id
  policy = data.aws_iam_policy_document.codedeploy_inline_policy.json
}
data "aws_iam_policy_document" "codedeploy_inline_policy" {
  statement {
    sid = "IAM"
    actions = [
      "iam:PassRole",
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
    sid = "ECS"
    actions = [
      "ecs:CreateTaskSet",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:DeleteTaskSet",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "ECR"
    actions = [
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "ELB"
    actions = [
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:ModifyRule",
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
