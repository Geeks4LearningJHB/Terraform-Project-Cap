##eks from our custom module
module "eks" {
  source     = "./modules/capitec_eks"
  subnets    = var.subnets
  user       = var.user
  eks_config = var.eks_config
}




