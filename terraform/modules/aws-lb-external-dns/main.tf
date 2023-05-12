# AWS Load Balancer IAM

#AllowExternalDNSUpdates
resource "aws_iam_policy" "awslbcEDnsPolicy" {
  name = var.awslbc_edns_policy_name
  description = "AWS Load Balancer External DNS IAM Policy"
  policy = jsonencode( {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "route53:ChangeResourceRecordSets"
        ],
        "Resource": [
          "${var.route53_hosted_zone_arn}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  })
}

locals {
  iam_openid_connect_provider = element(split("oidc-provider/","${var.iam_openid_connect_provider_arn}"),1)
}

# IAM Roles for Service Accounts
resource "aws_iam_role" "awslbcEDnsRole" {
  name = var.awslbc_edns_role_name
  description = "AWS Load Balancer External DNS IAM Role"
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
            "${local.iam_openid_connect_provider}:sub" : "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "awslbcRoleAttatch" {
  role = aws_iam_role.awslbcEDnsRole.name
  policy_arn = aws_iam_policy.awslbcEDnsPolicy.arn
}

# aws load balancer external dns to mange route53

resource "helm_release" "aws-load-balancer-controller" {
  name = "awslbc-edns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart = "external-dns"
  version = "1.12.2"
  namespace = "kube-system"
  values = [
    templatefile("../modules/aws-lb-external-dns/values_external-dns_v1.12.2.yaml", {
      awslbc_edns_iam_role_arn = "${aws_iam_role.awslbcEDnsRole.arn}"
    })
  ]
}