variable "subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "user" {
  type = object({
    surname  = string
    initials = string
  })
}

variable "eks_config" {
  type = object({
    k8s_version           = string
    env                   = string
    instance_type         = string
    max_nodes             = number
    min_nodes             = number
    desired_nodes         = number
    max_unavailable_nodes = number
    capacity_type         = string
  })
}

