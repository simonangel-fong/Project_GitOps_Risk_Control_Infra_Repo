output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_version" {
  value = module.eks.cluster_version
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_role_arn" {
  value = module.eks.cluster_role_arn
}

# ##############################
# Karpenter
#
# Consumed by the GitOps repo that installs the Karpenter Helm chart and
# applies EC2NodeClass / NodePool manifests.
#
#   queue_name             -> settings.interruptionQueue (Helm)
#   node_iam_role_name     -> EC2NodeClass.spec.role
#   cluster_name/endpoint  -> settings.clusterName / settings.clusterEndpoint
# ##############################
output "karpenter_queue_name" {
  description = "SQS interruption queue Karpenter watches for spot/maintenance events"
  value       = module.karpenter.queue_name
}

output "karpenter_node_iam_role_name" {
  description = "IAM role name used by Karpenter-launched nodes (referenced from EC2NodeClass.spec.role)"
  value       = module.karpenter.node_iam_role_name
}

