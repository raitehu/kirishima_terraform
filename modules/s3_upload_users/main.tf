resource "aws_iam_user" "flowerstand_ar_developer" {
  for_each = { for name in var.user_names : name => name }
  name     = each.value

  lifecycle {
    ignore_changes = [tags]
  }
}
resource "aws_iam_group" "flowerstand_ar_developers" {
  name = "flowerstand-ar-developers"
}


resource "aws_iam_user_group_membership" "flowerstand_ar_developers" {
  for_each = { for name in var.user_names : name => name }
  user     = each.value
  groups   = [aws_iam_group.flowerstand_ar_developers.name]

  depends_on = [
    aws_iam_group.flowerstand_ar_developers,
    aws_iam_user.flowerstand_ar_developer
  ]
}

resource "aws_iam_policy" "put_items" {
  name = "put-items-to-flowerstand-ar-s3-bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketVersions",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:ReplicateObject",
          "s3:RestoreObject"
        ]
        Resource = [
          "arn:aws:s3:::raitehu-flowerstand-ar",
          "arn:aws:s3:::raitehu-flowerstand-ar/*"
        ]
      }
    ]
  })
}
resource "aws_iam_group_policy_attachment" "put_items" {
  group      = aws_iam_group.flowerstand_ar_developers.name
  policy_arn = aws_iam_policy.put_items.arn
}
