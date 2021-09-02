variable "aws_region" {
    type = string
    default = "eu-west-1"
}

variable "subnets" {
  description = "The list of subnets to deploy an eks cluster"
  type        = list(string)
  default     = null
}

variable "kubernetes_version" {
  description = "The target version of kubernetes"
  type        = string
}

variable "name" {
  description = "The logical name of the module instance"
  type        = string
  default     = "eks"
}

variable "tags" {
  description = "The key-value maps for tagging"
  type        = map(string)
  default     = {}
}

variable "node_groups" {
  description = "Node groups definition"
  default     = []
}