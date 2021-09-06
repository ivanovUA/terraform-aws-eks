# Amazon EKS (Elastic Kubernetes Service)

[![LICENSE](https://img.shields.io/github/license/ivanovUA/terraform-aws-eks)](https://github.com/ivanovUA/terraform-aws-eks/blob/master/LICENSE)

[Amazon EKS](https://aws.amazon.com/eks/) is a fully managed Kubernetes service. Customers trust EKS to run their most sensitive and mission critical applications because of its security, reliability, and scalability.

This module will create EKS cluster on AWS. You can register multiple node groups.

## Usage example
```hcl
module "eks" {
    source = "github.com/ivanovUA/terraform-aws-eks"
    name = "Test-cluster"
    tags = { env = "test" }
    kubernetes_version = "1.19"
    subnets = [ "subnet-1234567890", "subnet-0987654321", "subnet-1a2b3c4d" ]
    node_groups = [
        {
            name          = "spot"
            min_size      = 1
            max_size      = 3
            desired_size  = 1
            instance_type = "t3.micro"
            instances_distribution = {
                spot_allocation_strategy = "lowest-price"
                spot_max_price           = "0.036"
            }
            instances_override = [
                {
                    instance_type = "t3.small"
                },
                {
                    instance_type = "t3a.small"
                },
                {
                    instance_type = "t2.small"
                }
            ]
        },
        {
            name          = "managed"
            min_size      = 1
            max_size      = 3
            desired_size  = 1
            instance_type = "t3.small"
        }
    ]
}
```

