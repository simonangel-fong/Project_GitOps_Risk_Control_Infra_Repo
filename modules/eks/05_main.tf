# main.tf

# ##############################
# Cluster IAM Role
# ##############################
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-cluster-role"

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
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# ##############################
# EKS Managed Add-ons
# ##############################
resource "aws_eks_addon" "this" {
  for_each = var.cluster_addons

  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = each.key
  addon_version               = each.value.addon_version
  service_account_role_arn    = each.value.service_account_role_arn
  configuration_values        = each.value.configuration_values
  resolve_conflicts_on_create = each.value.resolve_conflicts_on_create
  resolve_conflicts_on_update = each.value.resolve_conflicts_on_update

  tags = var.cluster_tags
}

# ##############################
# EKS Cluster
# ##############################
resource "aws_eks_cluster" "main" {
  name    = var.cluster_name
  version = var.cluster_version

  role_arn = aws_iam_role.cluster.arn
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
    public_access_cidrs     = var.endpoint_public_access ? var.public_access_cidrs : null
  }

  tags = merge(
    var.cluster_tags,
    { Name = var.cluster_name }
  )

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

# ##############################
# Cluster Security Group Tags
# (worker nodes use the cluster SG; tag it for Karpenter discovery, etc.)
# ##############################
resource "aws_ec2_tag" "cluster_security_group" {
  for_each = var.node_security_group_tags

  resource_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  key         = each.key
  value       = each.value
}

# ##############################
# OIDC Provider
# (required for IRSA — IAM roles assumed by service accounts)
# ##############################
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]

  tags = merge(
    var.cluster_tags,
    { Name = "${var.cluster_name}-oidc" }
  )
}
