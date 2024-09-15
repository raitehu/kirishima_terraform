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
