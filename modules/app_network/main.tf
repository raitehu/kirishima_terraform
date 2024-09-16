###################
#      Common     #
###################
resource "aws_lb" "web-front" {
  name               = "web-front"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

  enable_deletion_protection = true

  access_logs {
    bucket  = var.alb_log_bucket_id
    prefix  = "web-front"
    enabled = true
  }
}
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.web-front.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.kongoh_acm_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
resource "aws_lb_listener_certificate" "pleiades" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = var.pleiades_union_acm_arn
}
###################
#    moneybook    #
###################
resource "aws_lb_target_group" "moneybook" {
  name     = "moneybook"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/login"
  }
}
resource "aws_lb_target_group_attachment" "moneybook" {
  target_group_arn = aws_lb_target_group.moneybook.arn
  target_id        = var.app_server_id
  port             = 3000
}
resource "aws_lb_listener_rule" "moneybook" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.moneybook.arn
  }

  condition {
    host_header {
      values = ["money-book.pleiades-union.com"]
    }
  }
}
###################
#      kongoh     #
###################
resource "aws_lb_target_group" "kongoh" {
  name     = "kongoh"
  port     = 3030
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
resource "aws_lb_target_group_attachment" "kongoh" {
  target_group_arn = aws_lb_target_group.kongoh.arn
  target_id        = var.app_server_id
  port             = 3030
}
resource "aws_lb_listener_rule" "kongoh" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kongoh.arn
  }

  condition {
    host_header {
      values = ["kyoto-u.kongoh.xyz"]
    }
  }
}
