# ##############################################################
# IAM for AWS Load Balancer Controller (IRSA)
# ##############################################################

locals {
  albc_sa_namespace = "kube-system"
  albc_sa_name      = "aws-load-balancer-controller"
}

# Trust policy: only the ALBC ServiceAccount in kube-system can assume this role
data "aws_iam_policy_document" "albc_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${module.eks.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${local.albc_sa_namespace}:${local.albc_sa_name}"]
    }
  }
}

resource "aws_iam_role" "albc" {
  name               = "${module.eks.cluster_name}-albc"
  description        = "IRSA role for AWS Load Balancer Controller in ${module.eks.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.albc_assume.json

  tags = local.tags
}

resource "aws_iam_policy" "albc" {
  name        = "${module.eks.cluster_name}-albc"
  description = "Permissions for AWS Load Balancer Controller to manage ALBs/NLBs and related resources"
  policy      = file("${path.module}/manifests/iam-policy.json")

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "albc" {
  role       = aws_iam_role.albc.name
  policy_arn = aws_iam_policy.albc.arn
}

output "albc_role_arn" {
  description = "IAM role ARN to annotate on the aws-load-balancer-controller ServiceAccount"
  value       = aws_iam_role.albc.arn
}
