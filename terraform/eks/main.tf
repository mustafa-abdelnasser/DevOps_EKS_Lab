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
  ec2_name = "jump_ec2"
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
resource "helm_release" "metric-server" {
  name = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart = "metrics-server"
  version = "3.10.0"
  namespace = "kube-system"
  depends_on = [ 
    module.eks_cluster
   ]
}

# Install aws load balancer controller
module "aws-lb-controller" {
  source = "../modules/aws-lb-controller"
  depends_on = [
    module.eks_cluster
  ]
  eks_cluster_name = var.cluster_name
  iam_openid_connect_provider_arn = module.eks_cluster.iam_openid_connect_provider_arn
}

# external DNS
module "aws-lb-controller-edns" {
  source = "../modules/aws-lb-external-dns"
  depends_on = [
    module.eks_cluster,
    module.aws-lb-controller,
    module.aws_certificate_manger
  ]
  iam_openid_connect_provider_arn = module.eks_cluster.iam_openid_connect_provider_arn
}

# eks karpenter cluster auto-scaler
module "karpenter" {
  source = "../modules/karpenter-cluster-as"
  depends_on = [
    module.eks_cluster
  ]
  eks_cluster_name = var.cluster_name
  iam_openid_connect_provider_arn = module.eks_cluster.iam_openid_connect_provider_arn
  eks_node_role_name = module.eks_cluster.iam_eks_node_role_name
  eks_node_role_arn = module.eks_cluster.iam_eks_node_role_arn
}

## provisioner
data "kubectl_file_documents" "default_provisioner" {
  content = templatefile("../modules/karpenter-cluster-as/karpenter-provisioner.yaml",{
    cluster_name = var.cluster_name
  })
}

resource "kubectl_manifest" "default_provisioner" {
  for_each  = data.kubectl_file_documents.default_provisioner.manifests
  yaml_body = each.value
  depends_on = [
    module.eks_cluster,
    module.karpenter
  ]
}


# # create route53 dns hosted zone
# module "route53_zone" {
#   source = "../modules/Route53/public_hosted_zone"
#   dns_zone_name = var.dns_zone_name
# }

data "aws_route53_zone" "dns_zone" {
  name = var.dns_zone_name
}

# create certificate
module "aws_certificate_manger" {
  # depends_on = [ 
  #   module.route53_zone
  #  ]
  source = "../modules/aws_certificate_manger"
  # dns_zone_id = module.route53_zone.dns_zone_id
  dns_zone_id = data.aws_route53_zone.dns_zone.zone_id
  domain_name = "*.${var.domain_name}"
}

# install argocd
module "argo-cd" {
  source = "../modules/argo-cd"
  depends_on = [ 
    module.eks_cluster,
    module.aws-lb-controller,
    module.aws_certificate_manger
   ]
   certificate_arn = module.aws_certificate_manger.certificate_arn
   domain_name = var.domain_name
   #dns_zone_name = var.dns_zone_name
}

# install argocd app-of-apps
data "kubectl_file_documents" "app_of_apps" {
  content = file("../modules/argo-cd/app_of_apps.yaml")
}

resource "kubectl_manifest" "app_of_apps" {
  for_each  = data.kubectl_file_documents.app_of_apps.manifests
  yaml_body = each.value
  depends_on = [
    module.eks_cluster,
    module.argo-cd
  ]
}