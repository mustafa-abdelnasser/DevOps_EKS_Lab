resource "helm_release" "aws-load-balancer-controller" {
  name = "awslbc"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  version = "1.5.2"
  namespace = "kube-system"
  values = [
    templatefile("../modules/helm_charts/aws-load-balancer-controller/values_aws-lbc_v1.5.2.yaml", {
      awslbc_iam_role = var.awslbc_iam_role_arn, clusterName = var.eks_cluster_name
    })
  ]
}

