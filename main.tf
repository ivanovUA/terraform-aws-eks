data "aws_eks_cluster_auth" "control_plane" {
  name = format("%s", local.name)
}

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

resource "aws_launch_template" "node_group" {
    for_each = { for ng in var.node_groups : ng.name => ng }
    name = format("eks-%s", uuid())
    tags = merge(local.default-tags, local.eks-tag, var.tags)
    image_id = data.aws_ami.eks[each.key].id
    user_data = base64encode(
        templatefile(
            "${path.module}/templates/userdata.sh.tpl",
            {
                cluster_name = aws_eks_cluster.control_plane.name
                base64_cluster_ca = aws_eks_cluster.control_plane.certificate_authority.0.data
                api_server_url = aws_eks_cluster.control_plane.endpoint
                kubelet_more_extra_args = ""
                node_taints = length(each.value.taints) == 0 ? "" : join(",", [for k, v in lookup(each.value, "taints", {}) : "${k}=${v}"])
                node_labels = length(each.value.labels) == 0 ? "" : join(",", [for k, v in lookup(each.value, "labels", {}) : "${k}=${v}"])
                use_max_pods = var.node_use_max_pods
                
            }
        )
    )
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

resource "aws_autoscaling_group" "node_group" {
    for_each = { for ng in var.node_groups : ng.name => ng }
    name = format("eks-%s", uuid())
    vpc_zone_identifier = local.subnet_ids
    max_size = lookup(each.value, "max_size", 3)
    min_size = lookup(each.value, "min_size", 1)
    desired_capacity = lookup(each.value, "desired_size", 1)
    force_delete = true
    protect_from_scale_in = false
    termination_policies = ["Default"]
    enabled_metrics = [
        "GroupMinSize",
        "GroupMaxSize",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupPendingInstances",
        "GroupStandbyInstances",
        "GroupTerminatingInstances",
        "GroupTotalInstances",
    ]
    mixed_instances_policy {
      launch_template {
          launch_template_specification {
              launch_template_id = aws_launch_template.node_group[each.key].id
              version = aws_launch_template.node_group[each.key].latest_version
          }
          dynamic "override" {
              for_each = lookup(each.value, "instances_override", [])
              content {
                  instance_type = lookup(override.value, "instance_type", null)
                  weighted_capacity = lookup(override.value, "weighted_capacity", null)
              }
          }
      }

      dynamic "instances_distribution" {
          for_each = { for key, val in each.value : key => val if key == "instances_distribution" }
          content {
              on_demand_allocation_strategy = lookup(instances_distribution.value, "on_demand_allocation_strategy", null)
              on_demand_base_capacity = lookup(instances_distribution.value, "on_demand_base_capacity", null)
              on_demand_percentage_above_base_capacity = lookup(instances_distribution.value, "on_demand_percentage_above_base_capacity", null)
              spot_allocation_strategy = lookup(instances_distribution.value, "spot_allocation_strategy", null)
              spot_instance_pools = lookup(instances_distribution.value, "spot_instance_pools", null)
              spot_max_price = lookup(instances_distribution.value, "spot_max_price", null)
          }
      }
    }
    dynamic "tag" {
        for_each = merge(
            local.eks-tag,
            {
                "eks:nodegroup-name" = join("-", [aws_eks_cluster.control_plane.name, each.key])
            },
            {
                "Name" = join("-", [aws_eks_cluster.control_plane.name, each.key])
            }
        )
        content {
            key = tag.key
            value = tag.value
            propagate_at_launch = true
        }
    }
    lifecycle {
      create_before_destroy = true
      ignore_changes = [desired_capacity, name]
    }

    depends_on = [
      aws_iam_role.node_group,
      aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
      aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
      aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
      aws_iam_role_policy_attachment.CloudWatchAgentServerPolicy,
      aws_launch_template.node_group,
      kubernetes_config_map.aws-auth,
      kubernetes_config_map.aws-auth,
      null_resource.remove_aws_vpc_cni
    ]
}

provider "kubernetes" {
    host = aws_eks_cluster.control_plane.endpoint
    token = data.aws_eks_cluster_auth.control_plane.token
    cluster_ca_certificate = base64decode(aws_eks_cluster.control_plane.certificate_authority.0.data)
}


resource "kubernetes_config_map" "aws-auth" {
    metadata {
        name = "aws-auth"
        namespace = "kube-system"
    }

    data = {
        mapRoles = yamlencode(
            [{
                rolearn  = element(compact(aws_iam_role.node_group.*.arn), 0)
                username = "system:node:{{EC2PrivateDNSName}}"
                groups = ["system:bootstrappers", "system:nodes"]
            }]
        )
    }
    depends_on = [
        aws_eks_cluster.control_plane
    ]
}

resource "null_resource" "check_aws_credentials_are_available" {
    provisioner "local-exec" {
        command = <<-EOT
            sh -c '
                aws sts get-caller-identity
                if [ $? -ne 0 ]; then
                    echo "There was some issue trying to execute the AWS CLI."
                    echo "This might mean no valid credentials are configured."
                    exit 1
                fi'
        EOT
    }
}

resource "null_resource" "update_kubeconfig_with_cluster_info" {
    provisioner "local-exec" {
        command = <<-EOT
            aws eks update-kubeconfig --name ${aws_eks_cluster.control_plane.name} --region ${var.aws_region}
        EOT
    }

    depends_on = [
      null_resource.check_aws_credentials_are_available,
      aws_eks_cluster.control_plane
    ]
}

resource "null_resource" "remove_aws_vpc_cni" {
    count = var.use_calico_cni ? 1 : 0
    provisioner "local-exec" {
        command = <<-EOT
            kubectl --context='${aws_eks_cluster.control_plane.arn}' delete daemonset -n kube-system aws-node
        EOT
        interpreter = ["bash", "-c"]
    }
    depends_on = [
      null_resource.check_aws_credentials_are_available,
      null_resource.update_kubeconfig_with_cluster_info
    ]
}

resource "null_resource" "install_calico_cni" {
    count = var.use_calico_cni ? 1 : 0
    provisioner "local-exec" {
        command = <<-EOT
            kubectl --context='${aws_eks_cluster.control_plane.arn}' \
                apply -f https://docs.projectcalico.org/manifests/calico-vxlan.yaml
        EOT
        interpreter = ["bash", "-c"]
    }
    depends_on = [
      null_resource.remove_aws_vpc_cni,
      null_resource.check_aws_credentials_are_available,
      null_resource.update_kubeconfig_with_cluster_info
    ]
}