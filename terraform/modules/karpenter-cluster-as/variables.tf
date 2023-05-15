variable "iam_openid_connect_provider_arn" {
  description = "iam open ID connect provider"
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_node_role_name" {
  type = string
}