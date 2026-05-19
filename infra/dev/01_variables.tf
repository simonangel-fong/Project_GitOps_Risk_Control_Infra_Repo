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

# # ##############################
# # cloudflare
# # ##############################
# variable "cf_api_token" {
#   type      = string
#   sensitive = true
# }
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
