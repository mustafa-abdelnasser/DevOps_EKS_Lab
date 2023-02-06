resource "helm_release" "nginx-ingress-controller" {
  name = "nginx-ingress-controller"
  repository = "https://helm.nginx.com/stable"
  chart = "nginx-ingress"
  version = "0.16.1"
  values = [
    "${file("ingress_controller_values.yaml")}"
  ]
}