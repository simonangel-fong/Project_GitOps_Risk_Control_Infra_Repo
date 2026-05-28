# locals.tf
locals {
  # ##############################
  # ArgoCD conventions (per upstream docs)
  # ##############################
  namespace     = "argocd"
  release_name  = "argocd"
  root_app_name = "00-app-of-apps"

  # ##############################
  # Helm values
  # ##############################
  helm_values = templatefile("${path.module}/manifests/values.tftpl", {
    enable_notifications = var.enable_notifications
  })

  # ##############################
  # AppProject (scopes the root app-of-apps tree)
  # ##############################
  rendered_project = templatefile("${path.module}/manifests/project.tftpl", {
    namespace       = local.namespace
    project_name    = var.project_name
    gitops_repo_url = var.gitops_repo_url
  })

  # ##############################
  # Root Application (app-of-apps)
  # ##############################
  rendered_root_app = templatefile("${path.module}/manifests/app-of-apps.tftpl", {
    namespace            = local.namespace
    root_app_name        = local.root_app_name
    root_app_project     = "default"
    gitops_repo_url      = var.gitops_repo_url
    gitops_repo_revision = var.gitops_repo_revision
    gitops_repo_path     = var.gitops_repo_path
  })
}
