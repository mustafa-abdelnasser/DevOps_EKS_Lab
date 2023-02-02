
resource "aws_eks_cluster" "eks_cluster" {

    name = var.cluster_name
    version = var.cluster_version

    role_arn = var.cluster_role_arn
    
    vpc_config {
        subnet_ids = var.cluster_subnet_list
        endpoint_public_access = true
    }

}


resource "aws_eks_node_group" "eks_cluster_node_group" {
    for_each = var.cluster_node_groups

    cluster_name = aws_eks_cluster.eks_cluster.name
    node_group_name = each.value["name"]
    node_role_arn = var.node_role_arn
    subnet_ids = var.cluster_subnet_list
    disk_size = each.value["disk_size"]
    instance_types = each.value["instance_types"]
    capacity_type = each.value["capacity_type"]

    scaling_config {
        desired_size = each.value["desired_size"]
        max_size = each.value["max_size"]
        min_size = each.value["min_size"]
    }

    update_config {
        max_unavailable = 1
    }
}