# AWS Load Balancer IAM

resource "aws_iam_policy" "awslbcPolicy" {
  name = var.awslbc_policy_name
  description = "AWS Load Balancer IAM Policy"
  policy = file("../modules/iam/awslbc/AWSLoadBalancerControllerIAMPolicy.json")
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
            Federated = "${var.aws_iam_openid_connect_provider_arn}"
        },
        Condition = {
          StringEquals = {
            "${var.aws_iam_openid_connect_provider_arn_split}:aud" : "sts.amazonaws.com",
            "${var.aws_iam_openid_connect_provider_arn_split}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
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
