aws_region = "eu-west-1"
name = "test"
subnets = [ "subnet-1234567890", "subnet-0987654321", "subnet-1a2b3c4d" ]
tags = {
  env  = "dev"
}
kubernetes_version = "1.19"

use_calico_cni = true

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
    taints = {"spotinstance":"true:PreferNoSchedule"}
    labels = {}
    instances_override = [
      {
        instance_type = "t3.small"
      },
      {
        instance_type = "t3a.small"
      }
    ]
  }
]