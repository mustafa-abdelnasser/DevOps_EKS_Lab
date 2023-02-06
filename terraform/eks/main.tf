# create eks_iam_roles
module "eks_iam" {
  source = "../modules/iam"
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