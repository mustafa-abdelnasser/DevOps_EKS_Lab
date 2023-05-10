data "aws_ami" "os" {
  most_recent = true

  filter {
    name   = "name"
    values = var.ami_name_filter
  }

  filter {
    name   = "virtualization-type"
    values = var.ami_virtualization_type
  }

  owners = var.ami_owners
}

resource "aws_security_group" "public" {
  name = "public_sg"
  description = "public internet access"
  vpc_id = var.vpc_id

}

resource "aws_security_group_rule" "egress" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [ "0.0.0.0/0" ]
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_ssh" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    security_group_id = aws_security_group.public
}

resource "aws_instance" "ec2" {
  ami = data.aws_ami.os
  instance_type = var.ec2_instance_type
  subnet_id = var.subnet_id
  key_name = var.ec2_keypair_name
}

