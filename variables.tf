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