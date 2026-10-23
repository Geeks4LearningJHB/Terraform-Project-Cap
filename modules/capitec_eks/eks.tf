data "aws_vpc" "default" {
  default = true
}

data "aws_eks_cluster" "example" {
  name       = local.eks_cluster_name
  depends_on = [aws_eks_cluster.eks]
}

output "endpoint" {
  value = data.aws_eks_cluster.example.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = data.aws_eks_cluster.example.certificate_authority[0].data
}


resource "aws_subnet" "subnets" {
  for_each          = var.subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  # Nodes have no NAT; they need public IPs to reach the EKS API / ECR via the IGW
  map_public_ip_on_launch = true

  tags = {
    Name        = each.key
    ZONE        = each.value.availability_zone
    ENVIRONMENT = var.eks_config.env
  }
}

resource "aws_route_table_association" "rta" {
  for_each       = aws_subnet.subnets
  subnet_id      = each.value.id
  route_table_id = local.route_table_id
}

resource "aws_eks_cluster" "eks" {
  name = local.eks_cluster_name
  access_config {
    authentication_mode = "API"
  }
  role_arn = aws_iam_role.cluster_iam_role.arn
  version  = var.eks_config.k8s_version

  vpc_config {
    subnet_ids = [for s in aws_subnet.subnets : s.id]
  }
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]

  tags = {
    Name        = local.eks_cluster_name
    ENVIRONMENT = var.eks_config.env
  }
}

resource "aws_iam_role" "cluster_iam_role" {
  name = local.iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = local.iam_role_name
    ENVIRONMENT = var.eks_config.env
  }
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_iam_role.name
}

# authentication_mode = "API" means Kubernetes RBAC access is governed
# entirely by EKS access entries, not IAM policies or aws-auth. Without
# this, the IAM principal that creates/manages the cluster has no way
# to authenticate to the Kubernetes API.
data "aws_caller_identity" "current_caller" {}

resource "aws_eks_access_entry" "admin_access_entry" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = data.aws_caller_identity.current_caller.arn
  type          = "STANDARD"

  tags = {
    Name        = "EKS-Admin-Access-Entry"
    ENVIRONMENT = var.eks_config.env
  }
}

resource "aws_eks_access_policy_association" "admin_access_policy_association" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = aws_eks_access_entry.admin_access_entry.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

}

resource "aws_iam_role" "node_iam_role" {
  name = local.node_iam_role_name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_iam_role.name
}

resource "aws_security_group_rule" "nodeport_ingress" {
  type              = "ingress"
  from_port         = 30007
  to_port           = 30007
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  description       = "Allow inbound access to nginx NodePort service"
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = local.eks_node_group_name
  node_role_arn   = aws_iam_role.node_iam_role.arn
  subnet_ids      = [for s in aws_subnet.subnets : s.id]

  capacity_type  = var.eks_config.capacity_type
  instance_types = [var.eks_config.instance_type]

  scaling_config {
    min_size     = var.eks_config.min_nodes
    max_size     = var.eks_config.max_nodes
    desired_size = var.eks_config.desired_nodes
  }

  update_config {
    max_unavailable = var.eks_config.max_unavailable_nodes
  }

  # Ensure IAM permissions are created before and deleted after the
  # node group, otherwise EKS cannot properly bootstrap/tear down nodes.
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}
