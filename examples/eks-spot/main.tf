provider "aws" {
    region = var.aws_region
}

module "eks" {
    source = "../../"
    name = var.name
    tags = var.tags
    kubernetes_version = var.kubernetes_version
    node_groups = var.node_groups
    use_calico_cni = var.use_calico_cni
}