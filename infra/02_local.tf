locals {

  # ##############################
  # Project
  # ##############################
  project_name = "gitops-demo"

  # ##############################
  # AWS
  # ##############################
  tags = {
    Project     = local.project_name
    Environment = var.env
    ManagedBy   = "terraform"
  }

  # ##############################
  # VPC
  # ##############################
  vpc_name = "${local.project_name}-${var.env}"
  vpc_cidr = "10.0.0.0/16"

  # ##############################
  # EKS
  # ##############################
  cluster_name    = "${local.project_name}-${var.env}"
  cluster_version = "1.35"

  #   node_instance_types = ["t3.medium"]
  #   node_min_size       = 1
  #   node_max_size       = 3
  #   node_desired_size   = 2
  #   access_entries = {
  #     cluster_admin = {
  #       # principal_arn = "${aws_iam_role.eks_admin_access.arn}"
  #       principal_arn = var.cluster_admin_arn
  #       policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #       scope         = "cluster"
  #       namespaces    = []
  #       description   = "Human: daily ops and break-glass"
  #     }
  #     # github_cicd = {
  #     #   principal_arn = var.cluster_cicd_arn
  #     #   # policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  #     #   policy_arn  = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  #     #   scope       = "cluster"
  #     #   namespaces  = []
  #     #   description = "CI/CD App pipeline: Helm add-ons and application deployments"
  #     # }

  #     # developer = {
  #     #   principal_arn = var.developer_role_arn
  #     #   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
  #     #   scope         = "namespace"
  #     #   namespaces    = var.app_namespaces # e.g. ["app-backend", "app-frontend"]
  #     #   description   = "Human: app debugging and workload management, namespace-scoped"
  #     # }
  #     # auditor = {
  #     #   principal_arn = var.auditor_role_arn
  #     #   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #     #   scope         = "cluster"
  #     #   namespaces    = []
  #     #   description   = "Human: compliance and reporting, read-only"
  #     # }
  #   }

  #   # ##############################
  #   # Add-on
  #   # ##############################
  #   gitops_repo_url = "https://github.com/simonangel-fong/Project_GitOps_Config_Repo.git"

  #   # ##############################
  #   # Cloudflare
  #   # ##############################s
  #   dns_record = "arguswatcher.net"
  #   dns_name   = "${var.dns_prefix}.${local.dns_record}"
}
