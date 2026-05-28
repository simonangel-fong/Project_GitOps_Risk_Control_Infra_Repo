# main.tf

# ##############################
# ArgoCD Helm release
# ##############################
resource "helm_release" "argocd" {
  name             = local.release_name
  namespace        = local.namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version

  values = compact([
    local.helm_values,
    var.values,
  ])

  # Argo CRDs are large; give Helm time to install
  timeout = 600
  wait    = true
}

# # ##############################
# # AppProject (must exist before any Application that references it)
# # ##############################
# resource "kubectl_manifest" "project" {
#   yaml_body = local.rendered_project

#   depends_on = [helm_release.argocd]
# }

# ##############################
# Root Application (app-of-apps)
# ##############################
resource "kubectl_manifest" "root_app" {
  count = var.enable_root_app ? 1 : 0

  yaml_body = local.rendered_root_app

  # depends_on = [kubectl_manifest.project]
}
