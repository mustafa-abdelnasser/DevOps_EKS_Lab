variable "ami_owners" {
    type = list(string)
    # amazon "591542846629"
    default = ["amazon"]
}

variable "ami_name_filter" {
    type = list(string)
    # amazon linux 2023 image 
    default = ["al2023-ami-2023.*-x86_64"]
}

variable "ami_virtualization_type" {
    type = list(string)
    default = ["hvm"]
}

variable "ec2_instance_type" {
    type = string
    default = "t2.micro"
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
    type = string
}

variable "ec2_public_key" {
    type = string
}