locals {
    node_groups_enabled = (var.node_groups != null ? ((length(var.node_groups) > 0) ? true : false) : false)
    managed_node_groups_enabled = (var.managed_node_groups != null ? ((length(var.managed_node_groups) > 0) ? true : false) : false)   
}

resource "aws_eks_cluster" "control_plane" {
    name = format("%s", local.name)
    role_arn = aws_iam_role.control_plane.arn
    version = var.kubernetes_version
    tags = merge(local.default-tags, var.tags)

    vpc_config {
      subnet_ids = local.subnet_ids
    }
    
    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
        aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
    ]
}
