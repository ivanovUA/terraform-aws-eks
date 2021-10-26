variable "name" {
    description = "Name of the module instance"
    type = string
    default = null
}

variable "tags" {
    description = "Tags. Use key:value"
    type = map(string)
    default = {}
}

variable "policy_arns" {
    description = "List of policy ARNs for node group role"
    type = list(string)
    default = []
}

variable "node_groups" {
    description = "Node groups"
    default = []
}

variable "managed_node_groups" {
    description = "Managed Node groups"
    default = []
}

variable "subnets" {
    description = "List of subnets IDs"
    type = list(string)
    default = null
}

variable "kubernetes_version" {
    description = "Version of kubernetes"
    type = string
    default = "1.19"
}

variable "node_use_max_pods" {
    description = "Max pods inside one node"
    default = 110
}

variable "use_calico_cni" {
    type = bool
    default = false
}

variable "aws_region" {
    type = string
    default = "eu-west-1"
}