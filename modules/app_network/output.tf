output "web_front_alb_dns_name" {
  value = aws_lb.web-front.dns_name
}
output "web_front_alb_zone_id" {
  value = aws_lb.web-front.zone_id
}
output "listener_arn_https" {
  value = aws_lb_listener.https.arn
}
output "listener_arn_https_standby" {
  value = aws_lb_listener.https_standby.arn
}

# PRD
output "tg_arn_garland_prd" {
  value = aws_lb_target_group.garland_prd_blue.arn
}
output "tg_name_garland_prd_blue" {
  value = aws_lb_target_group.garland_prd_blue.name
}
output "tg_name_garland_prd_green" {
  value = aws_lb_target_group.garland_prd_green.name
}

# STG
output "tg_arn_garland_stg" {
  value = aws_lb_target_group.garland_stg_blue.arn
}
output "tg_name_garland_stg_blue" {
  value = aws_lb_target_group.garland_stg_blue.name
}
output "tg_name_garland_stg_green" {
  value = aws_lb_target_group.garland_stg_green.name
}
