resource "aws_vpc" "cloudgate" {
  cidr_block = local.cidr_block_vpc
  tags = {
    Name = "vpc_cloudgate"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = 3

  vpc_id            = aws_vpc.cloudgate.id
  cidr_block        = local.cidr_block_public[count.index]
  availability_zone = "${local.region}${local.availability_zone_suffix[count.index]}"
  tags = {
    Name = "sub_public_${local.availability_zone_suffix[count.index]}"
  }
}

# Security Groups
resource "aws_security_group" "default" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = aws_vpc.cloudgate.id

  ingress = []
  egress  = []
}

resource "aws_s3_bucket" "terraform_backend" {
  bucket = "cloudgate-terraform-backend"
}

resource "aws_s3_bucket_public_access_block" "terraform_backend_block_public_access" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
