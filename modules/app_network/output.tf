output "web_front_alb_dns_name" {
  value = aws_lb.web-front.dns_name
}
output "web_front_alb_zone_id" {
  value = aws_lb.web-front.zone_id
}
