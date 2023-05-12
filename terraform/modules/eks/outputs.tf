
output "endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "certificate_authority_data" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}

output "identity_issuer" {
  value = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

output "iam_eks_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "iam_eks_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}