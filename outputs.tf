output "tags" {
    description = "Generated Tags"
    value = {
        "shared" = local.eks-shared-tag
        "owned" = local.eks-owned-tag
        "elb" = local.eks-elb-tag
        "internal-elb" = local.eks-internal-elb-tag
    }
}