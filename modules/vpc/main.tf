#################
#      VPC      #
#################
resource "aws_vpc" "cloudgate" {
  cidr_block = var.cidr_block_vpc
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

  vpc_id            = aws_vpc.cloudgate.id
  cidr_block        = var.cidr_block_public[count.index]
  availability_zone = "${var.region}${var.availability_zone_suffix[count.index]}"
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
