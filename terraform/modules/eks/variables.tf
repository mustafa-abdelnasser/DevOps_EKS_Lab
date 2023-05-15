variable "cluster_role_name" {
    description = "eks cluster role name"
    type = string
    default = "EKSClusterRole"
}

variable "eks_cluster_tags" {
  type = map
}

variable "node_role_name" {
    description = "eks Node role name"
    type = string
    default = "EKSNodeRole"
}

variable "cluster_name" {
    description = "eks cluster name"
    type = string
}

variable "cluster_version" {
    description = "eks cluster version"
    type = string
}

variable "cluster_subnet_list" {
    description = "eks cluster subnet ids"
    type = list(string)
}

variable "cluster_node_groups" {
    description = "eks cluster node groups"
    type = map
    default = {
        node_group_1 = {
            name = "node_group_01"
            capacity_type = "ON_DEMAND"
            instance_types = ["t3.micro"]
            disk_size = 10
            desired_size = 2
            max_size = 3
            min_size = 1
        }
    }
}

variable "eks_node_group_pub_key" {
  type = string
}