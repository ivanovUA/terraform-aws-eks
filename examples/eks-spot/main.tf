provider "aws" {
    region = var.aws_region
}

module "eks" {
    source = "github.com/ivanovUA/terraform-aws-eks"
    name = var.name
    tags = var.tags
    kubernetes_version = var.kubernetes_version
    node_groups = var.node_groups
}