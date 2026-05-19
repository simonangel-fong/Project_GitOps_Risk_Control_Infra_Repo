# outputs.tf
output "cluster_id" { value = aws_eks_cluster.main.id }
output "cluster_name" { value = aws_eks_cluster.main.name }
output "cluster_arn" { value = aws_eks_cluster.main.arn }
output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_version" { value = aws_eks_cluster.main.version }
output "cluster_certificate_authority_data" { value = aws_eks_cluster.main.certificate_authority[0].data }
output "cluster_security_group_id" { value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id }
output "cluster_oidc_issuer_url" { value = aws_eks_cluster.main.identity[0].oidc[0].issuer }
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.this.arn }
output "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix — used in IRSA trust policy conditions"
  value       = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}
output "cluster_role_arn" { value = aws_iam_role.cluster.arn }
output "cluster_addons" {
  value = { for k, a in aws_eks_addon.this : k => {
    arn     = a.arn
    version = a.addon_version
  } }
}
