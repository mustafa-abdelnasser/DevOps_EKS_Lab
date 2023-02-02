
output "vpc_id" {
    value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.vpc_public_subnets
}

output "private_subnets" {
  value = aws_subnet.vpc_private_subnets
}

output "public_subnet_list" {
    value = [
        for subnet in aws_subnet.vpc_public_subnets : subnet.id
    ]
}

output "private_subnet_list" {
    value = [
        for subnet in aws_subnet.vpc_private_subnets : subnet.id
    ]
} 