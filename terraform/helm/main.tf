# cluster info
data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# certificate info
data "aws_acm_certificate" "domain" {
  domain      = "*.${var.domain_name}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

# eks_node_role
data "aws_iam_role" "eks_node_role" {
  name = var.eks_node_role_name
}

# install kubernetes Metric Server needed for kubectl top and HPA
resource "helm_release" "metric-server" {
  name = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart = "metrics-server"
  version = "3.10.0"
  namespace = "kube-system"
}


# Install aws load balancer controller
module "aws-lb-controller" {
  source = "../modules/aws-lb-controller"
  eks_cluster_name = var.cluster_name
  iam_openid_connect_provider_arn = data.aws_eks_cluster.cluster.iam_openid_connect_provider_arn
}

# external DNS
module "aws-lb-controller-edns" {
  source = "../modules/aws-lb-external-dns"
  depends_on = [
    module.aws-lb-controller
  ]
  iam_openid_connect_provider_arn = data.aws_eks_cluster.cluster.iam_openid_connect_provider_arn
}

# eks karpenter cluster auto-scaler
module "karpenter" {
  source = "../modules/karpenter-cluster-as"
  eks_cluster_name = var.cluster_name
  iam_openid_connect_provider_arn = data.aws_eks_cluster.cluster.iam_openid_connect_provider_arn
  eks_node_role_name = var.eks_node_role_name
  eks_node_role_arn = data.aws_iam_role.eks_node_role.arn
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
    module.karpenter
  ]
}

# install argocd
module "argo-cd" {
  source = "../modules/argo-cd"
  depends_on = [ 
    module.aws-lb-controller
   ]
   certificate_arn = data.aws_acm_certificate.domain.arn
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
    module.argo-cd
  ]
}