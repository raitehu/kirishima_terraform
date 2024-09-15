data "aws_ssm_parameter" "amazinlinux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "kongoh" {
  ami = data.aws_ssm_parameter.amazinlinux_2023.value
  # instance_type = "t3.micro"
  instance_type          = "c7a.large"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = "ec2"
  iam_instance_profile   = aws_iam_instance_profile.default.id
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  tags = {
    Name = "kongoh"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

data "aws_iam_policy_document" "ec2" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "ec2" {
  name               = "ec2-default"
  assume_role_policy = data.aws_iam_policy_document.ec2.json
}
resource "aws_iam_role_policy_attachment" "SSM" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
resource "aws_iam_instance_profile" "default" {
  name = aws_iam_role.ec2.name
  role = aws_iam_role.ec2.name
}
