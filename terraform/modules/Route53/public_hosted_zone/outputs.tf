output "dns_zone_name_servers" {
  value = aws_route53_zone.dns_zone.name_servers
}

output "dns_zone_id" {
  value = aws_route53_zone.dns_zone.zone_id
}