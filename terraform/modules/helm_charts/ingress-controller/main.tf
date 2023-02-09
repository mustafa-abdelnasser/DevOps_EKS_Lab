resource "helm_release" "nginx-ingress-controller" {
  name = "nginx-ingress"
  repository = "https://helm.nginx.com/stable"
  chart = "nginx-ingress"
  version = "0.16.1"
  namespace = "nginx-ingress"
  create_namespace = true
  values = [
    "${file("../modules/helm_charts/ingress-controller/ingress_controller_values.yaml")}"
  ]
}

data "kubernetes_service" "ingress_service" {
  depends_on = [
    helm_release.nginx-ingress-controller
  ]
  metadata {
    name = "nginx-ingress-service"
    namespace = "nginx-ingress"
  }
}
