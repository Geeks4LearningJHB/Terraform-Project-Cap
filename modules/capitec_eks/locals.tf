locals {
  eks_cluster_name    = "${var.user.surname}-${var.user.initials}-eks-${var.eks_config.env}"
  iam_role_name       = "${var.user.surname}-${var.user.initials}-eks-iam-role-${var.eks_config.env}"
  node_iam_role_name  = "${var.user.surname}-${var.user.initials}-eks-node-iam-role-${var.eks_config.env}"
  eks_node_group_name = "${var.user.surname}-${var.user.initials}-eks-node-group-${var.eks_config.env}"
  vpc_id              = data.aws_vpc.default.id
  route_table_id      = data.aws_vpc.default.main_route_table_id
}