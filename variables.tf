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