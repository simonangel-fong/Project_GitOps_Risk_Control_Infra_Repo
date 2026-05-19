# ##############################
# VPC
# ##############################
module "vpc" {
  source = "../../modules/vpc"

  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr
  vpc_tags = local.tags
}
