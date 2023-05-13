resource "helm_release" "argo-cd" {
  name = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "5.32.0"
  namespace = "argocd"
  create_namespace = true
  values = [
    templatefile("../modules/argo-cd/argo-cd_5.32.0_custom_values.yaml", {
      certificate_arn = var.certificate_arn, domain_name = var.domain_name
    })
  ]
}