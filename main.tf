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

data "aws_ami" "eks" {
    for_each = { for ng in var.node_groups : ng.name => ng }
    owners = ["amazon"]
    most_recent = true

    filter {
      name = "name"
      values = [format(length(regexall("ARM|GPU$", lookup(each.value, "ami_type", "AL2_x86_64"))) > 0 ? "amazon-eks-*-node-%s-*" : "amazon-eks-node-%s-*", var.kubernetes_version)]
    }

    filter {
      name = "architecture"
      values = [length(regexall("ARM", lookup(each.value, "ami_type", "AL2_x86_64"))) > 0 ? "arm64" : "x86_64"]
    }
}

data "template_cloudinit_config" "node_group" {
    for_each = { for ng in var.node_groups : ng.name => ng }
    base64_encode = true
    gzip = false

    part {
      content_type = "text/x-shellscript"
      content = <<-EOT
        #!/bin/bash
        set -ex
        /etc/eks/bootstrap.sh ${aws_eks_cluster.control_plane.name} --kubelet-extra-args 'eks.amazonaws.com/nodegroup=${join("-", [aws_eks_cluster.control_plane.name, each.key])}' --b64-cluster-ca ${aws_eks_cluster.control_plane.certificate_authority.0.data} --apiserver-endpoint ${aws_eks_cluster.control_plane.endpoint}
      EOT
    }
}

resource "aws_launch_template" "node_group" {
    for_each = { for ng in var.node_groups : ng.name => ng }
    name = format("eks-%s", uuid())
    tags = merge(local.default-tags, local.eks-tag, var.tags)
    image_id = data.aws_ami.eks[each.key].id
    user_data = base64encode(data.template_cloudinit_config.node_group[each.key].rendered)
    instance_type = lookup(each.value, "instance_type", "t3.medium")
    iam_instance_profile {
        arn = aws_iam_instance_profile.node_group.0.arn
    }
    block_device_mappings {
        device_name = "/dev/xvda"
        ebs {
            volume_size = lookup(each.value, "disk_size", "20")
            volume_type = "gp2"
            delete_on_termination = true
        }
    }
    network_interfaces {
      security_groups = [aws_eks_cluster.control_plane.vpc_config.0.cluster_security_group_id]
      delete_on_termination = true
    }
    tag_specifications {
        resource_type = "instance"
        tags = merge(local.eks-owned-tag, var.tags)
    }
    lifecycle {
        create_before_destroy = true
        ignore_changes = [name]
    }
}
