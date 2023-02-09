resource "helm_release" "argo-cd" {
  name = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  version = "5.19.15"
  namespace = "argo"
  create_namespace = true
  values = [
    "${file("../modules/helm_charts/argo-cd/argo_values.yaml")}"
  ]
}
