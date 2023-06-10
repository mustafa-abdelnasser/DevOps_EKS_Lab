variable "region" {
    description = "Region"
    type = string
    default = "us-east-1"
}

variable "access_key" {
  description = "aws access key"
  type = string
}

variable "secret_key" {
  description = "aws secret key"
  type = string
}

variable "cluster_name" {
    description = "eks cluster name"
    type = string
    default = "eks-cluster-01"
}

variable "eks_node_role_name" {
  type = string
}

variable "domain_name" {
  type = string
}

