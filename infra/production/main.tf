terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  access_key  = var.access_key
  secret_key  = var.secret_key
  region      = "KR"
  site        = "PUBLIC"
  support_vpc = true
}

resource "ncloud_login_key" "loginkey" {
  key_name = "prod-key"
}

resource "ncloud_vpc" "main" {
  ipv4_cidr_block = "10.10.0.0/16"
}

resource "ncloud_subnet" "main" {
  vpc_no         = ncloud_vpc.main.vpc_no
  subnet         = cidrsubnet(ncloud_vpc.main.ipv4_cidr_block, 8, 1)
  zone           = "KR-2"
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
}

resource "ncloud_access_control_group" "be" {
  name   = "be-acg-prod"
  vpc_no = ncloud_vpc.main.id
}

resource "ncloud_access_control_group_rule" "be" {
  access_control_group_no = ncloud_access_control_group.be.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "8000"
    description = "for django"
  }
}

resource "ncloud_network_interface" "be" {
  name      = "be-prod-nic"
  subnet_no = ncloud_subnet.main.id
  access_control_groups = [
    ncloud_vpc.main.default_access_control_group_no,
    ncloud_access_control_group.be.id
  ]
}

resource "ncloud_init_script" "be" {
  name = "be-script-prod"
  content = templatefile("${path.module}/be_init_script.tftpl", {
    password               = var.password
    db                     = var.db
    db_user                = var.db_user
    db_password            = var.db_password
    db_port                = var.db_port
    db_host                = ncloud_public_ip.db.public_ip
    django_settings_module = var.django_settings_module
    django_secret_key      = var.django_secret_key
  })
}

resource "ncloud_public_ip" "be" {
  server_instance_no = ncloud_server.be.instance_no
}

resource "ncloud_server" "be" {
  subnet_no                 = ncloud_subnet.main.id
  name                      = "lion-be-prod"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  login_key_name            = ncloud_login_key.loginkey.key_name
  init_script_no            = ncloud_init_script.be.init_script_no
  network_interface {
    network_interface_no = ncloud_network_interface.be.id
    order                = 0
  }
}

## DB


resource "ncloud_access_control_group" "db" {
  name   = "db-acg-prod"
  vpc_no = ncloud_vpc.main.id
}

resource "ncloud_access_control_group_rule" "db" {
  access_control_group_no = ncloud_access_control_group.db.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "5432"
    description = "for postgresql"
  }
}

resource "ncloud_network_interface" "db" {
  name      = "db-prod-nic"
  subnet_no = ncloud_subnet.main.id
  access_control_groups = [
    ncloud_vpc.main.default_access_control_group_no,
    ncloud_access_control_group.db.id
  ]
}

resource "ncloud_init_script" "db" {
  name = "db-script-prod"
  content = templatefile("${path.module}/db_init_script.tftpl", {
    password    = var.password
    db          = var.db
    db_user     = var.db_user
    db_password = var.db_password
    db_port     = var.db_port
  })
}

resource "ncloud_public_ip" "db" {
  server_instance_no = ncloud_server.db.instance_no
}

resource "ncloud_server" "db" {
  subnet_no                 = ncloud_subnet.main.id
  name                      = "lion-db-prod"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  # product_code
  login_key_name = ncloud_login_key.loginkey.key_name
  init_script_no = ncloud_init_script.db.init_script_no
  network_interface {
    network_interface_no = ncloud_network_interface.db.id
    order                = 0
  }
}

