variable "route53_hosted_zone_arn" {
  description = "Route53 Hosted Zone Url to have permissions on"
  type = string
  default = "arn:aws:route53:::hostedzone/*"
}

variable "awslbc_edns_policy_name" {
    description = "AWS Load Balancer External Dns IAM Policy"
    type = string
    default = "AWSLBExternalDNSIAMPolicy"
}

variable "awslbc_edns_role_name" {
    description = "aws load balancer controller role name"
    type = string
    default = "AWSLBExternalDNSIAMPolicyIAMRole"
}

variable "iam_openid_connect_provider_arn" {
  description = "value"
  type = string
  default = ""
}

