# variable.tf
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "subnet_ids" {
  description = "Subnet IDs where the EKS control plane ENIs will be placed (at least two AZs)"
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API endpoint is enabled"
  type        = bool
  default     = false
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint when enabled"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_tags" {
  description = "Tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}

variable "node_security_group_tags" {
  description = "Tags applied to the cluster security group used by worker nodes (e.g. karpenter.sh/discovery for Karpenter SG discovery)."
  type        = map(string)
  default     = {}
}

variable "cluster_addons" {
  description = "EKS managed add-ons to install. Map key is the add-on name (e.g. coredns, kube-proxy, vpc-cni, eks-pod-identity-agent). Set addon_version to null to use the latest compatible version."
  type = map(object({
    addon_version               = optional(string)
    service_account_role_arn    = optional(string)
    configuration_values        = optional(string)
    resolve_conflicts_on_create = optional(string, "OVERWRITE")
    resolve_conflicts_on_update = optional(string, "OVERWRITE")
  }))
  default = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }
  }
}
