# Route 53
# Kongoh
resource "aws_route53_zone" "kongoh" {
  name = "kongoh.xyz"
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
resource "aws_route53_record" "yakan" {
  zone_id = aws_route53_zone.kongoh.zone_id
  name    = "mukai.kongoh.xyz"
  type    = "A"

  alias {
    name                   = var.cloudfront_yakan_dns_name
    zone_id                = var.cloudfront_yakan_zone_id
    evaluate_target_health = true
  }
}
# pleiades-union
resource "aws_route53_zone" "pleiades" {
  name = "pleiades-union.com"
}
resource "aws_route53_record" "pleiades_union_A" {
  zone_id = aws_route53_zone.pleiades.zone_id
  name    = "pleiades-union.com"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "pleiades_union_A_www" {
  zone_id = aws_route53_zone.pleiades.zone_id
  name    = "www.pleiades-union.com"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
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
# raitehu.com
resource "aws_route53_zone" "raitehu" {
  name = "raitehu.com"
}
resource "aws_route53_record" "raitehu_A_garland_prd" {
  zone_id = aws_route53_zone.raitehu.zone_id
  name    = "garland.raitehu.com"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "raitehu_A_garland_stg" {
  zone_id = aws_route53_zone.raitehu.zone_id
  name    = "garland-stg.raitehu.com"
  type    = "A"

  alias {
    name                   = var.web_front_alb_dns_name
    zone_id                = var.web_front_alb_zone_id
    evaluate_target_health = true
  }
}
resource "aws_route53_record" "return_me_tags" {
  zone_id = aws_route53_zone.raitehu.zone_id
  name    = "returnmetags.raitehu.com"
  type    = "A"

  alias {
    name                   = var.cloudfront_return_me_tags_dns_name
    zone_id                = var.cloudfront_return_me_tags_zone_id
    evaluate_target_health = true
  }
}
