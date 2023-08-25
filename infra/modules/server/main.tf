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

## Network

data "ncloud_vpc" "main" {
  id = var.vpc_id
}

data "ncloud_subnet" "main" {
  id = var.subnet_id
}

## Server

resource "ncloud_login_key" "loginkey" {
  key_name = "lion-${var.name}-key-${var.env}"
}

resource "ncloud_access_control_group" "main" {
  vpc_no = data.ncloud_vpc.main.vpc_no
  name   = "${var.name}-acg-${var.env}"
}

resource "ncloud_access_control_group_rule" "main" {
  access_control_group_no = ncloud_access_control_group.main.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = var.acg_port_range
    description = "accept ${var.acg_port_range} port for ${var.name}"
  }
}

resource "ncloud_network_interface" "main" {
  name      = "${var.name}-nic-${var.env}"
  subnet_no = var.subnet_id
  access_control_groups = [
    data.ncloud_vpc.main.default_access_control_group_no,
    ncloud_access_control_group.main.id,
  ]
}

resource "ncloud_server" "main" {
  subnet_no                 = data.ncloud_subnet.main.id
  name                      = "${var.name}-${var.env}"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  server_product_code       = var.server_product_code
  login_key_name            = ncloud_login_key.loginkey.key_name
  init_script_no            = ncloud_init_script.main.init_script_no

  network_interface {
    network_interface_no = ncloud_network_interface.main.id
    order                = 0
  }
}

resource "ncloud_init_script" "main" {
  name = "set-${var.name}-tf-${var.env}"
  content = templatefile(
    "${path.module}/${var.init_script_path}",
    var.init_script_envs
  )
}
