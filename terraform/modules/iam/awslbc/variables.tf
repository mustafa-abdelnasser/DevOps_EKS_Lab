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

variable "aws_iam_openid_connect_provider_arn" {
  description = "value"
  type = string
  default = ""
}

variable "aws_iam_openid_connect_provider_arn_split" {
  description = "value"
  type = string
  default = ""
}