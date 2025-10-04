locals {
  config = yamldecode(file("${path.module}/../envs/${var.env}.yaml"))

  tags_final = merge(local.config.tags, { environment = var.env })

  infra_net = {
    vpc        = local.config.vpc
    subnets    = local.config.subnets
    tags       = local.tags_final
    aws_region = local.config.ec2.aws_region
  }

  config_with_tags = {
    vpc     = local.config.vpc
    subnets = local.config.subnets
    ec2     = local.config.ec2
    sql_db  = try(local.config.sql_db, null)
    tags    = local.tags_final
  }

  private_subnet_ids = [
    for name, id in module.vpc.subnet_ids_by_name : id
    if startswith(name, "private")
  ]
}

provider "aws" {
  region = local.config.ec2.aws_region
}

module "vpc" {
  source = "../modules/networking"
  infra  = local.infra_net
}

module "compute" {
  source    = "../modules/compute"
  infra     = local.config_with_tags
  subnet_id = module.vpc.subnet_ids_by_name[local.config.ec2.subnet_name]
}

module "database" {
  source      = "../modules/database"
  config      = local.config_with_tags
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = local.config.vpc.cidr
  subnet_ids  = local.private_subnet_ids
}
