terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  access_key  = var.NCP_ACCESS_KEY
  secret_key  = var.NCP_SECRET_KEY
  region      = "KR"
  site        = "PUBLIC"
  support_vpc = true
}

locals {
  env = "staging"
}

module "vpc" {
  source = "../modules/network"

  env            = local.env
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
}

module "servers" {
  source = "../modules/server"

  db                     = "lionforum"
  db_user                = var.db_user
  db_password            = var.db_password
  django_secret_key      = var.django_secret_key
  django_settings_module = "lion_app.settings.staging"
  NCP_ACCESS_KEY         = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY         = var.NCP_SECRET_KEY
  password               = var.password
  env                    = local.env
  vpc_id                 = module.vpc.vpc_id
}

module "load_balancer" {
  source = "../modules/loadBalancer"

  env            = local.env
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
  vpc_id         = module.vpc.vpc_id
  be_instance_no = module.servers.be_instance_no
}
