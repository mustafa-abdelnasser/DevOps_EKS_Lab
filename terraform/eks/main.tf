# create eks_iam_roles
module "eks_iam" {
  source = "../modules/iam/eks"
}

locals {
  public_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/nlb"                      = "1"
  }
  private_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-nlb"             = "1"
  }
}


# create VPC network
module "eks_networking" {
  source = "../modules/network"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  vpc_public_subnets = var.vpc_public_subnets
  vpc_private_subnets = var.vpc_private_subnets
  public_subnets_tags = local.public_subnets_tags
  private_subnets_tags = local.private_subnets_tags
}

# create eks cluster and node_groups
module "eks_cluster" {
  source = "../modules/eks"
  depends_on = [
    module.eks_iam,
    module.eks_networking
  ]
  cluster_name = var.cluster_name
  cluster_role_arn = module.eks_iam.iam_eks_cluster_role_arn
  cluster_subnet_list = module.eks_networking.private_subnet_list
  cluster_version = var.cluster_version
  
  node_role_arn = module.eks_iam.iam_eks_node_role_arn
  cluster_node_groups = var.cluster_node_groups
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = var.cluster_name
}

data "tls_certificate" "eks_cluster" {
  url = module.eks_cluster.identity_issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = module.eks_cluster.identity_issuer
}

module "iam_awslbc" {
  source = "../modules/iam/awslbc"
  aws_iam_openid_connect_provider_arn = aws_iam_openid_connect_provider.eks_cluster.arn
  aws_iam_openid_connect_provider_arn_split = element(split("oidc-provider/","${aws_iam_openid_connect_provider.eks_cluster.arn}"),1)
}

module "aws-load-balancer-controller" {
  source = "../modules/helm_charts/aws-load-balancer-controller"
  depends_on = [
    module.eks_cluster,
    aws_iam_openid_connect_provider.eks_cluster
  ]
  awslbc_iam_role_arn = module.iam_awslbc.iam_awslbcRole_arn
  eks_cluster_name = var.var.cluster_name
}


# module "nginx_ingress_controller" {
#   source = "../modules/helm_charts/ingress-controller"
#   depends_on = [
#     module.eks_cluster
#   ]
# }

# module "helm_aro-cd" {
#   source = "../modules/helm_charts/argo-cd"
#   depends_on = [
#     module.nginx_ingress_controller
#   ]
# }