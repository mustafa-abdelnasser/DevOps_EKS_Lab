output "argo-cd_ingress_hostname" {
    value = data.kubernetes_ingress_v1.argo-cd.status.0.load_balancer.0.ingress.0.hostname
}

