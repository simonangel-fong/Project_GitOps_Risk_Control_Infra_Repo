# ##############################
# Environemnt
# ##############################
variable "env" {
  type = string
}

# ##############################
# AWS
# ##############################
variable "aws_region" {
  type = string
}

# ##############################
# ArgoCD notifications
# ##############################
variable "slack_bot_token" {
  description = "Slack bot OAuth token (xoxb-...) for ArgoCD notifications. Stored in SSM and synced into argocd-notifications-secret by ESO. Leave empty to disable notifications."
  type        = string
  sensitive   = true
  default     = ""
}

# ##############################
# cloudflare
# ##############################
variable "cloudflare_api_key" {
  type      = string
  sensitive = true
}
# variable "dns_prefix" {
#   type = string
# }

# # ##############################
# # EKS Access
# # ##############################
# variable "cluster_admin_arn" {
#   description = "AWS arn for eks cluster admin access."
#   type        = string
#   sensitive   = true
# }

# # ##############################
# # TLS
# # ##############################
# variable "acm_cert_arn" {
#   description = "ARN of the ACM certificate covering the cluster hostnames (e.g. *.arguswatcher.net). Used by the Traefik NLB TLS listener."
#   type        = string
# }
