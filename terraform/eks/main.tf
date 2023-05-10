# create eks_iam_roles
module "eks_iam" {
  source = "../modules/iam/eks"
}

locals {
  public_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1"
  }
  private_subnets_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1"
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
module "ec2" {
  source = "../modules/simple_ec2"
  depends_on = [ module.eks_networking ]
  vpc_id = module.eks_networking.vpc_id
  subnet_id = module.eks_networking.public_subnet_list[0]
  ec2_instance_type = "t2.micro"
  ec2_public_key = var.eks_node_group_pub_key
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
  eks_node_group_pub_key = var.eks_node_group_pub_key
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = var.cluster_name
}

data "tls_certificate" "eks_cluster" {
  url = module.eks_cluster.identity_issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  depends_on = [ module.eks_cluster ]
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = module.eks_cluster.identity_issuer
}

module "iam_awslbc" {
  source = "../modules/iam/awslbc"
  aws_iam_openid_connect_provider_arn = aws_iam_openid_connect_provider.eks_cluster.arn
  aws_iam_openid_connect_provider_arn_split = element(split("oidc-provider/","${aws_iam_openid_connect_provider.eks_cluster.arn}"),1)
}

module "aws-load-balancer-controller-helm" {
  source = "../modules/helm_charts/aws-load-balancer-controller"
  depends_on = [
    module.eks_cluster,
    aws_iam_openid_connect_provider.eks_cluster
  ]
  awslbc_iam_role_arn = module.iam_awslbc.iam_awslbcRole_arn
  eks_cluster_name = var.cluster_name
}

# create route53 dns hosted zone
# module "route53_zone" {
#   source = "../modules/Route53/public_hosted_zone"
#   dns_zone_name = var.dns_zone_name
# }

# create certificate
module "aws_certificate_manger" {
  source = "../modules/aws_certificate_manger"
  dns_zone_name = var.dns_zone_name
  domain_name = "*.${var.domain_name}"
}

module "argo-cd-helm" {
  source = "../modules/helm_charts/argo-cd"
  depends_on = [ 
    module.eks_cluster,
    module.aws_certificate_manger
   ]
   certificate_arn = module.aws_certificate_manger.certificate_arn
   domain_name = var.domain_name
   dns_zone_name = var.dns_zone_name
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