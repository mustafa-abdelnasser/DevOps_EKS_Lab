# EKS IAM Roles and Policies
## EKS Cluster Role with AWS Managed Policies
resource "aws_iam_role" "eks_cluster_role" {
    name = "${var.cluster_role_name}-${var.cluster_name}"
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "eks.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role" {
    role = aws_iam_role.eks_cluster_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

## EKS Node Role with AWS Managed Policies
resource "aws_iam_role" "eks_node_role" {
    name = "${var.node_role_name}-${var.cluster_name}"
    assume_role_policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
        })
}

locals {
  eks_node_policies = ["AmazonEC2ContainerRegistryReadOnly", "AmazonEKSWorkerNodePolicy","AmazonEKS_CNI_Policy"]
}

resource "aws_iam_role_policy_attachment" "eks_node_role" {
  for_each = toset(local.eks_node_policies)

  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
  role       = aws_iam_role.eks_node_role.name
}

# create EKS cluster
resource "aws_eks_cluster" "eks_cluster" {

    name = var.cluster_name
    version = var.cluster_version
    role_arn = aws_iam_role.eks_cluster_role.arn
    
    vpc_config {
        subnet_ids = var.cluster_subnet_list
        endpoint_public_access = true
    }

}

# create node group ssh key from public key
resource "aws_key_pair" "eks_node_group_key" {
    key_name = "node_group_pub_key-${var.cluster_name}"
    public_key = var.eks_node_group_pub_key
}

resource "aws_eks_node_group" "eks_cluster_node_group" {
    for_each = var.cluster_node_groups

    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = each.value["name"]
    node_role_arn = aws_iam_role.eks_node_role.arn
    subnet_ids = var.cluster_subnet_list
    disk_size = each.value["disk_size"]
    instance_types = each.value["instance_types"]
    capacity_type = each.value["capacity_type"]
    ec2_ssh_key = aws_key_pair.eks_node_group_key.key_name

    scaling_config {
        desired_size = each.value["desired_size"]
        max_size = each.value["max_size"]
        min_size = each.value["min_size"]
    }

    update_config {
        max_unavailable = 1
    }
}

# configure iam open id connect for eks service accounts to use IAM roles
data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  depends_on = [ module.eks_cluster ]
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}
