variable "iam_openid_connect_provider_arn" {
  description = "iam open ID connect provider"
  type = string
}

variable "awslbc_policy_name" {
    description = "AWS Load Balancer IAM Policy"
    type = string
    default = "AWSLoadBalancerControllerIAMPolicy"
}

variable "awslbc_role_name" {
    description = "aws load balancer controller role name"
    type = string
    default = "AWSLoadBalancerControllerIAMRole"
}

variable "eks_cluster_name" {
  type = string
}