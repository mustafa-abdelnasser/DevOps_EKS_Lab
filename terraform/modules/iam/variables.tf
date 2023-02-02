variable "cluster_role_name" {
    description = "eks cluster role name"
    type = string
    default = "EKSClusterRole"
}

variable "node_role_name" {
    description = "eks Node role name"
    type = string
    default = "EKSNodeRole"
}


