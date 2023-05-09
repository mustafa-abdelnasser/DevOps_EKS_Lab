resource "helm_release" "argo-cd" {
  name = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "5.32.0"
  namespace = "argo-cd"
  create_namespace = true
  values = [
    templatefile("../modules/helm_charts/argo-cd/argo-cd_5.32.0_custom_values.yaml", {
      certificate_arn = var.certificate_arn, domain_name = var.domain_name
    })
  ]
}


data "kubernetes_ingress_v1" "argo-cd" {
  metadata {
    name = "argo-cd-argocd-server"
  }
}

data "aws_route53_zone" "dns_zone" {
  name         = var.dns_zone_name
}

resource "aws_route53_record" "argo-cd" {
  zone_id = data.aws_route53_zone.dns_zone.id
  name    = "argocd.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_ingress_v1.argo-cd.status.0.load_balancer.0.ingress.0.hostname]
}