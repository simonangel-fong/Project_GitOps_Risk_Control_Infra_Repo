# ##############################
# VPC
# ##############################
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr
  vpc_tags = local.tags
}

# ##############################
# EKS
# ##############################
module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  subnet_ids      = module.vpc.private_subnet_ids
  cluster_tags    = local.tags
}

# ##############################
# EKS Node Group
# ##############################
module "eks_node_group" {
  source = "../../modules/eks_node_group"

  cluster_name    = module.eks.cluster_name
  node_group_name = "bootstrap"
  subnet_ids      = module.vpc.private_subnet_ids

  instance_types = ["t3.medium"]
  desired_size   = 1
  min_size       = 1
  max_size       = 3

  node_group_tags = local.tags
}

# ##############################
# ArgoCD
# ##############################
module "eks_argocd" {
  source = "../../modules/eks_argocd"

  namespace      = "argocd"
  release_name   = "argocd"
  chart_version  = "9.5.14"

  # Extra Helm values merged on top of module defaults
  values = yamlencode({
    server = {
      service = { type = "LoadBalancer" }
    }
  })

  # Root app-of-apps
  enable_root_app      = true
  gitops_repo_url      = "https://github.com/simonangel-fong/Project_GitOps_Platform_Repo.git"
  gitops_repo_revision = "main"
  gitops_repo_path     = "bootstrap"
  root_app_name        = "root"
  root_app_project     = "default"

  depends_on = [module.eks_node_group]
}