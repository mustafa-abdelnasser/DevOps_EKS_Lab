# IAM Roles and Polices for Nodes provisioned by Karpenter

resource "aws_iam_role_policy_attachment" "karpenter_ssm_policy" {
  role = var.eks_node_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile
resource "aws_iam_instance_profile" "KarpenterNodeInstanceProfile" {
  name = "KarpenterNodeInstanceProfile-${var.eks_cluster_name}"
  role = var.eks_node_role_name
}

# IAM Roles and Polices for Karpenter controller
locals {
  iam_openid_connect_provider = element(split("oidc-provider/","${var.iam_openid_connect_provider_arn}"),1)
}

data "aws_eks_cluster" "eks_cluster" {
  name = var.eks_cluster_name
}

resource "aws_iam_role" "KarpenterControllerRole" {
  name = "KarpenterControllerRole-${var.eks_cluster_name}"
  description = "KarpenterController IAM Role"
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
            "${local.iam_openid_connect_provider}:sub" : "system:serviceaccount:karpenter:karpenter"
          }
        }
      }
    ]
  })
}




resource "aws_iam_policy" "KarpenterControllerPolicy" {
  name = "KarpenterControllerPolicy-${var.eks_cluster_name}"
  description = "KarpenterController IAM Policy"
  policy = jsonencode({
        "Statement": [
            {
                "Action": [
                    # write operations
                    "ec2:CreateFleet",
                    "ec2:CreateLaunchTemplate",
                    "ec2:CreateTags",
                    "ec2:DeleteLaunchTemplate",
                    "ec2:RunInstances",
                    #"ec2:TerminateInstances",
                    # Read Operations
                    "ec2:DescribeAvailabilityZones",
                    "ec2:DescribeImages",
                    "ec2:DescribeInstances",
                    "ec2:DescribeInstanceTypeOfferings",
                    "ec2:DescribeInstanceTypes",
                    "ec2:DescribeLaunchTemplates",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeSpotPriceHistory",
                    "ec2:DescribeSubnets",
                    "pricing:GetProducts",
                    "ssm:GetParameter"
                ],
                "Effect": "Allow",
                "Resource": "*",
                "Sid": "Karpenter"
            },
            {
                "Action": "ec2:TerminateInstances",
                "Condition": {
                    "StringLike": {
                        "ec2:ResourceTag/karpenter.sh/provisioner-name": "*"
                    }
                },
                "Effect": "Allow",
                "Resource": "*",
                "Sid": "ConditionalEC2Termination"
            },
            {
                "Action": [
                    "sqs:DeleteMessage",
                    "sqs:GetQueueAttributes",
                    "sqs:GetQueueUrl",
                    "sqs:ReceiveMessage"
                ],
                "Effect": "Allow",
                "Resource": "${aws_sqs_queue.KarpenterInterruptionQueue.arn}"
            },
            {
                "Effect": "Allow",
                "Action": "iam:PassRole",
                "Resource": "${var.eks_node_role_arn}",
                "Sid": "PassNodeIAMRole"
            },
            {
                "Effect": "Allow",
                "Action": "eks:DescribeCluster",
                "Resource": "${data.aws_eks_cluster.eks_cluster.arn}",
                "Sid": "EKSClusterEndpointLookup"
            }
        ],
        "Version": "2012-10-17"
    })
}

resource "aws_sqs_queue" "KarpenterInterruptionQueue" {
    name = var.eks_cluster_name
    message_retention_seconds = 300
    sqs_managed_sse_enabled = true
}


resource "aws_sqs_queue_policy" "KarpenterInterruptionQueuePolicy" {
    queue_url = aws_sqs_queue.KarpenterInterruptionQueue.id
    policy = <<EOF
    {
      "Version": "2008-10-17",
      "Id": "EC2InterruptionPolicy",
      "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Service": [
                "events.amazonaws.com",
                "sqs.amazonaws.com"
              ]
            },
            "Action": "sqs:SendMessage",
            "Resource": "${aws_sqs_queue.KarpenterInterruptionQueue.arn}"
          }
      ]
    }
  EOF
}

####################
resource "aws_cloudwatch_event_rule" "ScheduledChangeRule" {
  name        = "KarpenterScheduledChangeRule"
  description = "Karpenter ScheduledChangeRule"

  event_pattern = jsonencode({
    "detail-type": ["AWS Health Event"],
    "source": ["aws.health"]
  })
}

resource "aws_cloudwatch_event_target" "ScheduledChangeRule" {
  rule      = aws_cloudwatch_event_rule.ScheduledChangeRule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.KarpenterInterruptionQueue.arn
}

####################
resource "aws_cloudwatch_event_rule" "SpotInterruptionRule" {
  name        = "KarpenterSpotInterruptionRule"
  description = "Karpenter SpotInterruptionRule"

  event_pattern = jsonencode({
    "detail-type": ["EC2 Spot Instance Interruption Warning"],
    "source": ["aws.ec2"]
  })
}

resource "aws_cloudwatch_event_target" "SpotInterruptionRule" {
  rule      = aws_cloudwatch_event_rule.SpotInterruptionRule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.KarpenterInterruptionQueue.arn
}

####################
resource "aws_cloudwatch_event_rule" "RebalanceRule" {
  name        = "KarpenterRebalanceRule"
  description = "Karpenter RebalanceRule"

  event_pattern = jsonencode({
    "detail-type": ["EC2 Instance Rebalance Recommendation"],
    "source": ["aws.ec2"]
  })
}

resource "aws_cloudwatch_event_target" "RebalanceRule" {
  rule      = aws_cloudwatch_event_rule.RebalanceRule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.KarpenterInterruptionQueue.arn
}

####################
resource "aws_cloudwatch_event_rule" "InstanceStateChangeRule" {
  name        = "KarpenterInstanceStateChangeRule"
  description = "Karpenter InstanceStateChangeRule"

  event_pattern = jsonencode({
    "detail-type": ["EC2 Instance State-change Notification"],
    "source": ["aws.ec2"]
  })
}

resource "aws_cloudwatch_event_target" "InstanceStateChangeRule" {
  rule      = aws_cloudwatch_event_rule.InstanceStateChangeRule.name
  target_id = "KarpenterInterruptionQueueTarget"
  arn       = aws_sqs_queue.KarpenterInterruptionQueue.arn
}

# Karpenter helm install

resource "helm_release" "karpenter" {
  name = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart = "karpenter"
  version = "0.16.3"
  namespace = "karpenter"
  create_namespace = true
  values = [
    templatefile("../modules/karpenter-cluster-as/values_karpenter_0.16.3.yaml", {
      karpenter_controller_role_arn = aws_iam_role.KarpenterControllerRole.arn, 
      eks_cluster_name = var.eks_cluster_name,
      eks_cluster_endpoint = data.aws_eks_cluster.eks_cluster.endpoint,
      KarpenterNodeInstanceProfile = aws_iam_instance_profile.KarpenterNodeInstanceProfile.name
    })
  ]
}
