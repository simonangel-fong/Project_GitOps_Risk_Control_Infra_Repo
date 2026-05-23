# variable.tf

# ##############################
# ArgoCD chart
# ##############################
variable "namespace" {
  description = "Namespace where ArgoCD is installed"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for argo-cd"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Version of the argo-cd Helm chart (https://artifacthub.io/packages/helm/argo/argo-cd)"
  type        = string
  default     = "9.5.14"
}

variable "values" {
  description = "Additional Helm values YAML for argo-cd, merged on top of module defaults"
  type        = string
  default     = ""
}

# ##############################
# Root Application (app-of-apps)
# ##############################
variable "enable_root_app" {
  description = "Whether to create the root app-of-apps Application after ArgoCD is installed"
  type        = bool
  default     = true
}

variable "gitops_repo_url" {
  description = "Git URL of the GitOps config repo that ArgoCD will sync from"
  type        = string
}

variable "gitops_repo_revision" {
  description = "Git revision (branch, tag, or commit) ArgoCD tracks for the root application"
  type        = string
  default     = "HEAD"
}

variable "gitops_repo_path" {
  description = "Path inside the GitOps repo containing the root app-of-apps manifests"
  type        = string
  default     = "bootstrap"
}

variable "root_app_name" {
  description = "Name of the root Argo Application (app-of-apps)"
  type        = string
  default     = "root"
}

variable "root_app_project" {
  description = "ArgoCD project the root application belongs to"
  type        = string
  default     = "default"
}

variable "enable_notifications" {
  description = "Enable ArgoCD notifications sub-component (Slack only, for now). Requires argocd-notifications-secret to exist with key 'slack-token' (managed by ESO)."
  type        = bool
  default     = false
}

variable "notifications_default_subscriptions" {
  description = "Optional cluster-wide notification subscriptions. Each entry is a {recipients, triggers} object. Leave empty to require per-Application annotations."
  type = list(object({
    recipients = list(string) # e.g. ["slack:my-channel"]
    triggers   = list(string) # e.g. ["on-sync-failed", "on-health-degraded"]
  }))
  default = []
}

variable "notifications_extra_values" {
  description = "Extra Helm values YAML merged into the notifications block (custom templates, triggers, etc.). Applied after the module-generated notifications block, before var.values."
  type        = string
  default     = ""
}
