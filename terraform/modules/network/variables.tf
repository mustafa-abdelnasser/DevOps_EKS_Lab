
variable "vpc_name" {
    description = "VPC Name"
    type = string
    default = "custom-vpc"
}


variable "vpc_cidr" {
    description = "VPC CIDR"
    type = string
    default = "192.168.0.0/16"
}

variable "vpc_public_subnets" {
    description = "VPC Public Subnets"
    type    = map
    default = {
        public_subnet_1 = {
            az = "us-east-1a"
            cidr = "192.168.1.0/24"
        }
        public_subnet_1 = {
            az = "us-east-1b"
            cidr = "192.168.2.0/24"
        }
    }
}

variable "vpc_private_subnets" {
    description = "VPC Private Subnets"
    type    = map
    default = {
        private_subnet_1 = {
            az = "us-east-1a"
            cidr = "192.168.11.0/16"
        }
        private_subnet_1 = {
            az = "us-east-1b"
            cidr = "192.168.12.0/24"
        }
    }
}