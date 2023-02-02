

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