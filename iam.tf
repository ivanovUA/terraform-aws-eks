resource "aws_iam_role" "control_plane" {
    name = format("%s-cp", local.name)
    tags = merge(local.default-tags, var.tags)
    assume_role_policy = jsonencode({
        Version : "2012-10-17",
        Statement : [
        {
            Effect : "Allow",
            Principal : {
            Service : "eks.amazonaws.com"
            },
            Action : "sts:AssumeRole"
        }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role = aws_iam_role.control_plane.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
    role = aws_iam_role.control_plane.name
}

resource "aws_iam_role" "node_group" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    name  = format("%s-ng", local.name)
    tags  = merge(local.default-tags, var.tags)
    assume_role_policy = jsonencode({
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }]
        Version = "2012-10-17"
    })
}

resource "aws_iam_instance_profile" "node_group" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    name  = format("%s-ng", local.name)
    role = aws_iam_role.node_group.0.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.node_group.0.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role = aws_iam_role.node_group.0.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.node_group.0.name
}

resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
    count = local.node_groups_enabled || local.managed_node_groups_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    role = aws_iam_role.node_group.0.name
}

