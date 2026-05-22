# main.tf

# ##############################
# ArgoCD Helm release
# ##############################
resource "helm_release" "argocd" {
  name             = var.release_name
  namespace        = var.namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version

  values = compact([
    local.default_values,
    local.notifications_values,
    var.notifications_extra_values,
    var.values,
  ])

  # Argo CRDs are large; give Helm time to install
  timeout = 600
  wait    = true
}

# ##############################
# Root Application (app-of-apps)
# ##############################
resource "kubectl_manifest" "root_app" {
  count = var.enable_root_app ? 1 : 0

  yaml_body = yamlencode(local.root_application)

  depends_on = [helm_release.argocd]
}
