# locals.tf
locals {
  default_values = yamlencode({
    global = {
      domain = ""
    }
    server = {
      service = {
        type = "ClusterIP"
      }
    }
  })

  # argocd-notifications-secret is owned by ESO (ExternalSecret in the GitOps
  # repo) and must NOT be created by the Helm chart. The notifications
  # controller resolves `$slack-token` against that secret at runtime.
  notifications_values = var.enable_notifications ? yamlencode({
    notifications = merge(
      {
        enabled = true
        notifiers = {
          # Chart expects this as a YAML-formatted STRING (copied verbatim
          # into argocd-notifications-cm), not a nested map.
          "service.slack" = "token: $slack-token\n"
        }
      },
      length(var.notifications_default_subscriptions) > 0
      ? { subscriptions = var.notifications_default_subscriptions }
      : {}
    )
  }) : ""

  root_application = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = var.root_app_name
      namespace = var.namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io",
      ]
    }
    spec = {
      project = var.root_app_project
      source = {
        repoURL        = var.gitops_repo_url
        targetRevision = var.gitops_repo_revision
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true",
        ]
      }
    }
  }
}
