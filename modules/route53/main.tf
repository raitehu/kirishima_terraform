# Route 53
# Kongoh
resource "aws_route53_zone" "kongoh" {
  name = "kongoh.xyz"
}
resource "aws_route53_record" "kongoh_A" {
  zone_id = aws_route53_zone.kongoh.zone_id
  name    = "*.kongoh.xyz"
  type    = "A"
  ttl     = "300"
  records = [var.on_premises_ip]
}
resource "aws_route53_record" "kyoto-u" {
  zone_id = aws_route53_zone.kongoh.zone_id
  name    = "kyoto-u.kongoh.xyz"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
}
# pleiades-union
resource "aws_route53_zone" "pleiades" {
  name = "pleiades-union.com"
}
resource "aws_route53_record" "pleiades_union_A" {
  zone_id = aws_route53_zone.pleiades.zone_id
  name    = "*.pleiades-union.com"
  type    = "A"
  ttl     = "300"
  records = [var.on_premises_ip]
}
resource "aws_route53_record" "moneybook" {
  zone_id = aws_route53_zone.pleiades.zone_id
  name    = "money-book.pleiades-union.com"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
}
