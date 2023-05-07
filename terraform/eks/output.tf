
output "public_subnets" {
    value = module.eks_networking.public_subnets
}

output "private_subnets" {
    value = module.eks_networking.private_subnets
}

output "public_subnet_list" {
    value = [
        for subnet in module.eks_networking.public_subnets : subnet.id
    ]
}

output "private_subnet_list" {
    value = [
        for subnet in module.eks_networking.private_subnets : subnet.id
    ]
}

output "eks_cluster_endpoint" {
  value = module.eks_cluster.endpoint
}

output "eks_cluster_certificate_authority" {
  value = module.eks_cluster.certificate_authority_data
}

output "eks_cluster_token-test" {
  value = data.aws_eks_cluster_auth.eks_cluster.token
  sensitive = true
}

# output "nginx_ingress_controller_service" {
#   value = module.nginx_ingress_controller.ingress_controller_service
# }