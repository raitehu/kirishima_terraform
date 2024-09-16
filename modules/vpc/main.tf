#################
#      VPC      #
#################
resource "aws_vpc" "cloudgate" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc_cloudgate"
  }
}

##################
#     Subnet     #
##################
# Public Subnets
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.cloudgate.id
  cidr_block              = var.cidr_block_public[count.index]
  availability_zone       = "${var.region}${var.availability_zone_suffix[count.index]}"
  map_public_ip_on_launch = true
  tags = {
    Name = "sub_public_${var.availability_zone_suffix[count.index]}"
  }
}
# Private Subnets
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.cloudgate.id
  cidr_block        = var.cidr_block_private[count.index]
  availability_zone = "${var.region}${var.availability_zone_suffix[count.index]}"
  tags = {
    Name = "sub_private_${var.availability_zone_suffix[count.index]}"
  }
}

#####################
#    Route Tables   #
#####################
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.cloudgate.id
  tags = {
    Name = "rtb-private"
  }
}
resource "aws_route_table_association" "rtb_private_1a" {
  route_table_id = aws_route_table.private_route.id
  subnet_id      = aws_subnet.private[0].id
}
resource "aws_route_table_association" "rtb_private_1c" {
  route_table_id = aws_route_table.private_route.id
  subnet_id      = aws_subnet.private[1].id
}

#####################
#  Security Groups  #
#####################
resource "aws_security_group" "default" {
  name        = "default"
  description = "default VPC security group"
  vpc_id      = aws_vpc.cloudgate.id

  ingress = []
  egress  = []
}
resource "aws_security_group" "elb" {
  name   = "elb"
  vpc_id = aws_vpc.cloudgate.id
}
resource "aws_security_group_rule" "ingress_elb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
resource "aws_security_group_rule" "ingress_elb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
resource "aws_security_group_rule" "ingress_elb_rails" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3030
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
resource "aws_security_group_rule" "egress_elb_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
resource "aws_security_group" "rds" {
  name   = "rds"
  vpc_id = aws_vpc.cloudgate.id
}
resource "aws_security_group_rule" "ingress_rds" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.elb.id
}
resource "aws_security_group_rule" "egress_rds_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
}
resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = aws_vpc.cloudgate.id
}
resource "aws_security_group_rule" "ingress_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["3.112.23.0/29"]
  security_group_id = aws_security_group.ssh.id
}
resource "aws_security_group_rule" "egress_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh.id
}
