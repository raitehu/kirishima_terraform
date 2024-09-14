# VPC
output "vpc_id" {
  value = aws_vpc.cloudgate.id
}
# Subnet
output "subnet_public_a_id" {
  value = aws_subnet.public[0].id
}
output "subnet_public_c_id" {
  value = aws_subnet.public[1].id
}
output "subnet_private_a_id" {
  value = aws_subnet.private[0].id
}
output "subnet_private_c_id" {
  value = aws_subnet.private[1].id
}
# Security Group
output "sg_elb_id" {
  value = aws_security_group.elb.id
}
output "sg_rds_id" {
  value = aws_security_group.rds.id
}
