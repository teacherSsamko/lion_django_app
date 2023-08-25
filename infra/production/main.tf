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
  env     = "prod"
  db      = "lionforum"
  db_port = "5432"
}

module "network" {
  source = "../modules/network"

  env            = local.env
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
}

module "db_server" {
  source = "../modules/server"

  name           = "db"
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
  env            = local.env
  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.subnet_id
  init_script_envs = {
    db          = "lionforum"
    db_user     = var.db_user
    db_password = var.db_password
    db_port     = var.db_port
    password    = var.password

  }
  init_script_path    = "db_init_script.tftpl"
  server_product_code = data.ncloud_server_products.sm.server_products[0].product_code
  acg_port_range      = "5432"
}

module "be_server" {
  source = "../modules/server"

  name           = "be"
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
  env            = local.env
  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.subnet_id
  init_script_envs = {
    db                     = "lionforum"
    db_user                = var.db_user
    db_password            = var.db_password
    db_port                = var.db_port
    db_host                = ncloud_public_ip.db.public_ip
    password               = var.password
    django_secret_key      = var.django_secret_key
    django_settings_module = "lion_app.settings.production"
  }
  init_script_path    = "be_init_script.tftpl"
  server_product_code = data.ncloud_server_products.sm.server_products[0].product_code
  acg_port_range      = "8000"
}

module "load_balancer" {
  source = "../modules/loadBalancer"

  env            = local.env
  NCP_ACCESS_KEY = var.NCP_ACCESS_KEY
  NCP_SECRET_KEY = var.NCP_SECRET_KEY
  vpc_id         = module.network.vpc_id
  be_instance_no = module.be_server.instance_no
}

resource "ncloud_public_ip" "be" {
  server_instance_no = module.be_server.instance_no
}

resource "ncloud_public_ip" "db" {
  server_instance_no = module.db_server.instance_no
}

data "ncloud_server_products" "sm" {
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"

  filter {
    name   = "product_code"
    values = ["SSD"]
    regex  = true
  }

  filter {
    name   = "cpu_count"
    values = ["2"]
  }

  filter {
    name   = "memory_size"
    values = ["4GB"]
  }

  filter {
    name   = "base_block_storage_size"
    values = ["50GB"]
  }

  filter {
    name   = "product_type"
    values = ["HICPU"]
  }

  output_file = "product.json"
}
