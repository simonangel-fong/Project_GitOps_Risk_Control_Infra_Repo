# ##############################################################
# IAM for External Secrets Operator (IRSA)
# ##############################################################

locals {
  eso_sa_namespace = "external-secrets"
  eso_sa_name      = "external-secrets"
}

# Trust policy: only the ESO ServiceAccount in external-secrets can assume this role
data "aws_iam_policy_document" "eso_assume" {
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
      values   = ["system:serviceaccount:${local.eso_sa_namespace}:${local.eso_sa_name}"]
    }
  }
}

resource "aws_iam_role" "eso" {
  name               = "${module.eks.cluster_name}-eso"
  description        = "IRSA role for External Secrets Operator in ${module.eks.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.eso_assume.json

  tags = local.tags
}

# Permissions for ESO to read parameters from SSM Parameter Store.
data "aws_iam_policy_document" "eso" {
  statement {
    sid    = "ReadSSMParameters"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters",
    ]
    resources = ["*"]
  }

  # Uncomment if any of your SSM parameters are SecureString encrypted with a CMK
  # (not needed for the AWS-managed alias/aws/ssm key).
  # statement {
  #   sid       = "DecryptWithCMK"
  #   effect    = "Allow"
  #   actions   = ["kms:Decrypt"]
  #   resources = [aws_kms_key.ssm.arn]
  # }
}

resource "aws_iam_policy" "eso" {
  name        = "${module.eks.cluster_name}-eso"
  description = "Permissions for External Secrets Operator to read SSM parameters"
  policy      = data.aws_iam_policy_document.eso.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

output "eso_role_arn" {
  description = "IAM role ARN to annotate on the external-secrets ServiceAccount"
  value       = aws_iam_role.eso.arn
}

resource "aws_ssm_parameter" "cloudflare_api_key" {
  name        = "/gitops/cloudflare/cloudflare-api-key"
  description = "The cloudflare api key "
  type        = "SecureString"
  value       = var.cloudflare_api_key

  tags = local.tags
}

resource "aws_ssm_parameter" "argocd_slack_token" {
  count = var.slack_bot_token != "" ? 1 : 0

  name        = "/gitops/argocd/slack-token"
  description = "Slack bot OAuth token (xoxb-...) consumed by ArgoCD notifications via ESO"
  type        = "SecureString"
  value       = var.slack_bot_token

  tags = local.tags
}
