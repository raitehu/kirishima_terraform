output "web_front_alb_dns_name" {
  value = aws_lb.web-front.dns_name
}
output "web_front_alb_zone_id" {
  value = aws_lb.web-front.zone_id
}
output "tg_arn_garland_prd" {
  value = aws_lb_target_group.garland_prd.arn
}
output "tg_arn_garland_stg" {
  value = aws_lb_target_group.garland_stg.arn
}
