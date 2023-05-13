output "argo-cd_ingress_hostname" {
    value = "https://argocd.${var.domain_name}"
}