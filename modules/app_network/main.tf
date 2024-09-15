resource "aws_lb" "web-front" {
  name               = "web-front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = true
}
