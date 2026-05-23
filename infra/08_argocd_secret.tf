# argocd_secret.tf
# ##############################################################
# Argocd: cluster secret
# ##############################################################

resource "kubectl_manifest" "gitops_secret" {
  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = "gitops-secret"
      namespace = "argocd"
      labels = {
        "argocd.argoproj.io/secret-type" = "cluster"
      }
      annotations = {
        "eso.role-arn"           = aws_iam_role.eso.arn
        "eks.cluster-endpoint"   = module.eks.cluster_endpoint
        "eks.interruption-queue" = module.karpenter.queue_name
        "vpc.vpc-id"             = module.vpc.vpc_id
        "albc.role-arn"          = aws_iam_role.albc.arn
      }
    }
    type = "Opaque"
    stringData = {
      name   = "in-cluster"
      server = "https://kubernetes.default.svc"
      config = jsonencode({
        tlsClientConfig = {
          insecure = false
        }
      })
    }
  })

  depends_on = [
    module.eks_argocd,
  ]
}
