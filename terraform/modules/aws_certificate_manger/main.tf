
# data "aws_route53_zone" "dns_zone" {
#   name         = var.dns_zone_name
# }

resource "aws_acm_certificate" "certificate" {
  domain_name = var.domain_name
  validation_method = "DNS"
}


resource "aws_route53_record" "certificate_dns" {
  allow_overwrite = true
  name =  tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_name
  records = [tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_value]
  type = tolist(aws_acm_certificate.certificate.domain_validation_options)[0].resource_record_type
  zone_id = var.dns_zone_name.id
  ttl = 60
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [aws_route53_record.certificate_dns.fqdn]
}