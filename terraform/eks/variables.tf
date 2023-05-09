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

variable "cluster_version" {
    description = "eks cluster version"
    type = string
    default = "1.23"
}

variable "vpc_name" {
    description = "VPC Name"
    type = string
    default = "eks_vpc"
}

variable "vpc_cidr" {
    description = "VPC CIDR"
    type = string
    default = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
    description = "VPC Public Subnets"
    type    = map
    default = {
        public_subnet_1 = {
            az = "us-east-1a"
            cidr = "10.0.1.0/24"
        }
        public_subnet_2 = {
            az = "us-east-1b"
            cidr = "10.0.2.0/24"
        }
        public_subnet_3 = {
            az = "us-east-1c"
            cidr = "10.0.3.0/24"
        }
    }
}

variable "vpc_private_subnets" {
    description = "VPC Private Subnets"
    type    = map
    default = {
        private_subnet_1 = {
            az = "us-east-1a"
            cidr = "10.0.11.0/24"
        }
        private_subnet_2 = {
            az = "us-east-1b"
            cidr = "10.0.12.0/24"
        }
        private_subnet_3 = {
            az = "us-east-1c"
            cidr = "10.0.13.0/24"
        }
    }
}

variable "cluster_node_groups" {
    description = "eks cluster node groups"
    type = map
    default = {
        node_group_1 = {
            name = "node_group_01"
            capacity_type = "ON_DEMAND"
            instance_types = ["t3.medium"]
            disk_size = 10
            desired_size = 2
            max_size = 4
            min_size = 1
        }
        node_group_2 = {
            name = "node_group_02"
            capacity_type = "ON_DEMAND"
            instance_types = ["t3.micro"]
            disk_size = 10
            desired_size = 2
            max_size = 4
            min_size = 1
        }
    }
}

variable "dns_zone_name" {
  description = "route 53 zone name"
  type = string
}

variable "domain_name" {
  type = string
}