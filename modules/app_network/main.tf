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
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web-front.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      host        = "#{host}"
      port        = "443"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301" # permanent
    }
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
resource "aws_lb_listener" "https_standby" {
  load_balancer_arn = aws_lb.web-front.arn
  port              = "8443"
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
resource "aws_lb_listener_certificate" "raitehu" {
  listener_arn    = aws_lb_listener.https.arn
  certificate_arn = var.raitehu_acm_arn
}
resource "aws_lb_listener_certificate" "pleiades_standby" {
  listener_arn    = aws_lb_listener.https_standby.arn
  certificate_arn = var.pleiades_union_acm_arn
}
resource "aws_lb_listener_certificate" "raitehu_standby" {
  listener_arn    = aws_lb_listener.https_standby.arn
  certificate_arn = var.raitehu_acm_arn
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
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.moneybook.arn
  }

  condition {
    host_header {
      values = ["money-book.pleiades-union.com"]
    }
  }

  tags = {
    Name = "moneybook"
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
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kongoh.arn
  }

  condition {
    host_header {
      values = ["kyoto-u.kongoh.xyz"]
    }
  }

  tags = {
    Name = "kongoh"
  }
}
###################
#     garland     #
###################
resource "aws_lb_target_group" "garland_prd_blue" {
  name        = "prd-garland-blue"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
resource "aws_lb_target_group" "garland_prd_green" {
  name        = "prd-garland-green"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
resource "aws_lb_target_group" "garland_stg_blue" {
  name        = "stg-garland-blue"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
resource "aws_lb_target_group" "garland_stg_green" {
  name        = "stg-garland-green"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}
resource "aws_lb_listener_rule" "garland_prd" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 350

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.garland_prd_blue.arn
  }

  condition {
    host_header {
      values = ["garland.raitehu.com"]
    }
  }

  tags = {
    Name = "garland_prd"
  }

  lifecycle {
    ignore_changes = [action]
  }
}
resource "aws_lb_listener_rule" "garland_prd_standby" {
  listener_arn = aws_lb_listener.https_standby.arn
  priority     = 350

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.garland_prd_green.arn
  }

  condition {
    host_header {
      values = ["garland.raitehu.com"]
    }
  }

  tags = {
    Name = "garland_prd"
  }

  lifecycle {
    ignore_changes = [action]
  }
}
resource "aws_lb_listener_rule" "garland_stg" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.garland_stg_blue.arn
  }

  condition {
    host_header {
      values = ["garland-stg.raitehu.com"]
    }
  }

  tags = {
    Name = "garland_stg"
  }

  lifecycle {
    ignore_changes = [action]
  }
}
resource "aws_lb_listener_rule" "garland_stg_standby" {
  listener_arn = aws_lb_listener.https_standby.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.garland_stg_green.arn
  }

  condition {
    host_header {
      values = ["garland-stg.raitehu.com"]
    }
  }

  tags = {
    Name = "garland_stg"
  }

  lifecycle {
    ignore_changes = [action]
  }
}
###################
#     redirect    #
###################
# www.* -> *
resource "aws_lb_listener_rule" "remove_www_kongoh" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 1

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      host        = "kongoh.xyz"
      port        = "#{port}"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301" # permanent
    }
  }

  condition {
    host_header {
      values = ["www.kongoh.xyz"]
    }
  }

  tags = {
    Name = "remove-www"
  }
}
resource "aws_lb_listener_rule" "remove_www_pleiades-union" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 2

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      host        = "pleiades-union.com"
      port        = "#{port}"
      path        = "/#{path}"
      query       = "#{query}"
      status_code = "HTTP_301" # permanent
    }
  }

  condition {
    host_header {
      values = ["www.pleiades-union.com"]
    }
  }

  tags = {
    Name = "remove-www"
  }
}

# (www.)pleiades-union.com/mukai* -> mukai.kongoh.xyz(CloudFront/S3)
resource "aws_lb_listener_rule" "mukai" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 50

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      host        = "mukai.kongoh.xyz"
      port        = "443"
      path        = "/"
      query       = "#{query}"
      status_code = "HTTP_301" # permanent
    }
  }

  condition {
    host_header {
      values = ["pleiades-union.com", "www.pleiades-union.com"]
    }
  }
  condition {
    path_pattern {
      values = ["/mukai*"]
    }
  }

  tags = {
    Name = "redirect-mukai"
  }
}

# money-book.pleiades-union.com/ -> money-book.pleiades-union.com/login
resource "aws_lb_listener_rule" "moneybook_root" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 60

  action {
    type = "redirect"

    redirect {
      protocol    = "HTTPS"
      host        = "#{host}"
      port        = "#{port}"
      path        = "/login"
      query       = "#{query}"
      status_code = "HTTP_302" # temporary
    }
  }

  condition {
    host_header {
      values = ["money-book.pleiades-union.com"]
    }
  }
  condition {
    path_pattern {
      values = ["/"]
    }
  }

  tags = {
    Name = "redirect-moneybook-root"
  }
}
