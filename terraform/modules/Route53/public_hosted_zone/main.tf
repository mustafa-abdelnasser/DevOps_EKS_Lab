
resource "aws_route53_zone" "devops-labs" {
  name = var.dns_zone_name
}