# eks subnet tags
locals {
  public_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }
  private_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
    "karpenter.sh/discovery" = var.cluster_name
    "aws:eks:cluster-name" = var.cluster_name
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

# create pubic ec2










# create opensearch domain
module "opensearch" {
  source = "../modules/opensearch"
  depends_on = [ module.eks_networking ]
  vpc_id = module.eks_networking.vpc_id
  opensearch_domain = "opensearch-eks"
  opensearch_engine_version = "OpenSearch_2.5"
  opensearch_instance_type = "t3.small.search"
  opensearch_instance_count = 3
  opensearch_dedicated_master_type = "t3.small.search"
  opensearch_dedicated_master_count = 3
}

# create eks cluster and node_groups
module "eks_cluster" {
  source = "../modules/eks"
  depends_on = [
    module.eks_networking
  ]
  cluster_name = var.cluster_name
  cluster_subnet_list = module.eks_networking.private_subnet_list
  cluster_version = var.cluster_version
  cluster_node_groups = var.cluster_node_groups
  eks_node_group_pub_key = var.eks_node_group_pub_key
  eks_cluster_tags = var.eks_cluster_tags
}




# install kubernetes Metric Server needed for kubectl top and HPA