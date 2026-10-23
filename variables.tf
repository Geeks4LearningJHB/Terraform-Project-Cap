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

  validation {
    condition     = can(regex("^[a-z]+$", var.user.surname)) && can(regex("^[a-z]{1,3}$", var.user.initials))
    error_message = "surname and initials must be lowercase letters (initials: 1-3 chars), since they go into AWS resource names."
  }
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

  validation {
    condition     = contains(["dev", "qa", "prod"], var.eks_config.env)
    error_message = "eks_config.env must be one of: dev, qa, prod."
  }

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.eks_config.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }

  validation {
    condition = (
      var.eks_config.min_nodes >= 1 &&
      var.eks_config.min_nodes <= var.eks_config.desired_nodes &&
      var.eks_config.desired_nodes <= var.eks_config.max_nodes
    )
    error_message = "Node counts must satisfy 1 <= min_nodes <= desired_nodes <= max_nodes."
  }
}

