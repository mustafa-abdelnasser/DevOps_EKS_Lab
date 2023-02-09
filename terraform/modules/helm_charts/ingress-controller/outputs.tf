
output "ingress_controller_service" {
  value = data.kubernetes_service.ingress_service.status.0.load_balancer.0.ingress.0.hostname
}