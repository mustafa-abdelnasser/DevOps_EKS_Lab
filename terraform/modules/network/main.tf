# get availability zones
data "aws_availability_zones" "available" {}


resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = var.vpc_name
    }
  
}

resource "aws_subnet" "vpc_public_subnets" {
    for_each = var.vpc_public_subnets
    
    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value["cidr"]
    availability_zone = each.value["az"]

    tags = "${merge({Name = "${var.vpc_name}-${each.key}"},var.public_subnets_tags)}"

}

resource "aws_subnet" "vpc_private_subnets" {
    for_each = var.vpc_private_subnets

    vpc_id = aws_vpc.vpc.id
    cidr_block = each.value["cidr"]
    availability_zone = each.value["az"]
    tags = "${merge({Name = "${var.vpc_name}-${each.key}"},var.private_subnets_tags)}"
}

# Create InternetGW and attach it to VPC
resource "aws_internet_gateway" "vpc_internet_gw" {
    tags = {
        Name = "${var.vpc_name}-internet-gw"
    }
}

resource "aws_internet_gateway_attachment" "vpc_internet_gw_attach" {
    vpc_id = aws_vpc.vpc.id
    internet_gateway_id = aws_internet_gateway.vpc_internet_gw.id
    depends_on = [
      aws_internet_gateway.vpc_internet_gw
    ]
}

# Public route table to internet-gw
resource "aws_route_table" "vpc_public_route_table" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${var.vpc_name}-public-route-table"
    }
}

resource "aws_route" "vpc_public_route_any_to_internet_gw" {
    route_table_id = aws_route_table.vpc_public_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_internet_gw.id
}

resource "aws_route_table_association" "vpc_public_subnet_associate" {
    for_each = var.vpc_public_subnets

    route_table_id = aws_route_table.vpc_public_route_table.id
    subnet_id = aws_subnet.vpc_public_subnets[each.key].id
}


# NatGw EIP

resource "aws_eip" "vpc_nat_gw_eip" {

    depends_on = [
      aws_internet_gateway_attachment.vpc_internet_gw_attach
    ]

    tags = {
        Name = "${var.vpc_name}-nat-gw-eip"
    }
}

resource "aws_nat_gateway" "vpc_nat_gw" {
    depends_on = [
      aws_eip.vpc_nat_gw_eip,
      aws_internet_gateway.vpc_internet_gw,
      aws_subnet.vpc_public_subnets
    ]

    allocation_id = aws_eip.vpc_nat_gw_eip.id
    subnet_id = aws_subnet.vpc_public_subnets["public_subnet_1"].id

    tags = {
        Name = "${var.vpc_name}-nat-gw"
    }
}

# Private route tables to nat-gateways
resource "aws_route_table" "vpc_private_route_table" {
    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.vpc_name}-private-route-table"
    }
}

resource "aws_route" "vpc_private_route_any_to_nat_gw" {
    depends_on = [
      aws_nat_gateway.vpc_nat_gw
    ]
    route_table_id = aws_route_table.vpc_private_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc_nat_gw.id
}

resource "aws_route_table_association" "vpc_private_subnet_associate" {
    for_each = var.vpc_private_subnets

    route_table_id = aws_route_table.vpc_private_route_table.id
    subnet_id = aws_subnet.vpc_private_subnets[each.key].id
}