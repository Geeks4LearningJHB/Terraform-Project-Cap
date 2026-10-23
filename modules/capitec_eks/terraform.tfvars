subnets = {
  az1 = { availability_zone = "af-south-1a", cidr_block = "172.31.0.0/20" },
  az2 = { availability_zone = "af-south-1c", cidr_block = "172.31.16.0/20" },
  az3 = { availability_zone = "af-south-1b", cidr_block = "172.31.32.0/20" }
}

user = {
  surname  = "seema"
  initials = "mt"
}

eks_config = {
  k8s_version           = "1.35"
  env                   = "dev"
  instance_type         = "t3.small"
  max_nodes             = 2
  min_nodes             = 1
  desired_nodes         = 1
  max_unavailable_nodes = 1
  capacity_type         = "ON_DEMAND"
}