# AWS Load Balancer IAM Policy and Role

locals {
  iam_openid_connect_provider = element(split("oidc-provider/","${var.iam_openid_connect_provider_arn}"),1)
}

resource "aws_iam_policy" "awslbcPolicy" {
  name = var.awslbc_policy_name
  description = "AWS Load Balancer IAM Policy"
  policy = file("../modules/aws-lb-controller/AWSLoadBalancerControllerIAMPolicy.json")
}


resource "aws_iam_role" "awslbcRole" {
  name = var.awslbc_role_name
  description = "AWS Load Balancer IAM Role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
            Federated = "${var.iam_openid_connect_provider_arn}"
        },
        Condition = {
          StringEquals = {
            "${local.iam_openid_connect_provider}:aud" : "sts.amazonaws.com",
            "${local.iam_openid_connect_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
})
}

resource "aws_iam_role_policy_attachment" "awslbcRoleAttatch" {
  role = aws_iam_role.awslbcRole.name
  policy_arn = aws_iam_policy.awslbcPolicy.arn
}


# AWS Load Balancer Controller helm chart
resource "helm_release" "aws-load-balancer-controller" {
  name = "awslbc"
  repository = "https://aws.github.io/eks-charts"
  chart = "aws-load-balancer-controller"
  version = "1.5.2"
  namespace = "kube-system"
  values = [
    templatefile("../modules/aws-lb-controller/values_aws-lbc_v1.5.2.yaml", {
      awslbc_iam_role = aws_iam_role.awslbcRole.arn, eks_cluster_name = var.eks_cluster_name
    })
  ]
}

