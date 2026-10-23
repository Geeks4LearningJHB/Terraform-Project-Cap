subnets = {
  az1 = { availability_zone = "af-south-1a", cidr_block = "172.31.174.0/24" },
  az2 = { availability_zone = "af-south-1c", cidr_block = "172.31.175.0/24" },
  az3 = { availability_zone = "af-south-1b", cidr_block = "172.31.176.0/24" }
}

user = {
  surname  = "seema"
  initials = "mt"
}

eks_config = {
  k8s_version           = "1.35"
  env                   = "prod"
  instance_type         = "t3.small"
  max_nodes             = 2
  min_nodes             = 1
  desired_nodes         = 1
  max_unavailable_nodes = 1
  capacity_type         = "ON_DEMAND"
}
