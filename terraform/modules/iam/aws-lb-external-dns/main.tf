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
  aws_iam_openid_connect_provider = element(split("oidc-provider/","${aws_iam_openid_connect_provider.eks_cluster.arn}"),1)
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
            Federated = "${var.aws_iam_openid_connect_provider_arn}"
        },
        Condition = {
          StringEquals = {
            "${local.aws_iam_openid_connect_provider}:aud" : "sts.amazonaws.com",
            "${local.aws_iam_openid_connect_provider}:sub" : "system:serviceaccount:kube-system:external-dns"
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
