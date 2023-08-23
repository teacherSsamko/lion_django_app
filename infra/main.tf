terraform {
  required_providers {
    ncloud = {
      source = "NaverCloudPlatform/ncloud"
    }
  }
  required_version = ">= 0.13"
}

provider "ncloud" {
  access_key = var.NCP_ACCESS_KEY
  secret_key = var.NCP_SECRET_KEY
  region      = "KR"
  site = "PUBLIC"
  support_vpc = true
}

variable "NCP_ACCESS_KEY" {
  type = string
}

variable "NCP_SECRET_KEY" {
  type = string
  sensitive = true
}

variable "password" {
  type = string
  sensitive = true
}

resource "ncloud_login_key" "loginkey" {
  key_name = "lion-test-key"
}

resource "ncloud_vpc" "main" {
  ipv4_cidr_block = "10.1.0.0/16"
  name = "lion-tf"
}

resource "ncloud_subnet" "main" {
  vpc_no         = ncloud_vpc.main.vpc_no
  subnet         = cidrsubnet(ncloud_vpc.main.ipv4_cidr_block, 8, 1)
  zone           = "KR-2"
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PUBLIC"
  usage_type     = "GEN"
  name = "lion-tf-sub"
}

resource "ncloud_access_control_group" "be" {
  vpc_no      = ncloud_vpc.main.vpc_no
  name = "be-acg"
}

data "ncloud_access_control_group" "default" {
    id = "124474" # lion-tf-default-acg
}

resource "ncloud_access_control_group_rule" "be" {
 access_control_group_no = ncloud_access_control_group.be.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "8000"
    description = "accept 8000 port for django"
  }
}

resource "ncloud_network_interface" "be" {
    name                  = "be-nic"
    subnet_no             = ncloud_subnet.main.id
    access_control_groups = [
        ncloud_vpc.main.default_access_control_group_no,
        ncloud_access_control_group.be.id,
    ]
}

resource "ncloud_server" "be" {
  subnet_no                 = ncloud_subnet.main.id
  name                      = "be-staging"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  server_product_code = data.ncloud_server_products.sm.server_products[0].product_code
  login_key_name            = ncloud_login_key.loginkey.key_name
  init_script_no = ncloud_init_script.be.init_script_no

  network_interface {
    network_interface_no = ncloud_network_interface.be.id
    order = 0
  }
}

resource "ncloud_init_script" "be" {
  name    = "set-be-tf"
  content = templatefile("${path.module}/be_init_script.tftpl", {
    password = var.password
    db = var.db
    db_user = var.db_user
    db_password = var.db_password
    db_port = var.db_port
    db_host = ncloud_public_ip.db.public_ip
    django_secret_key = var.django_secret_key
    django_settings_module = var.django_settings_module
  })
}

variable "db" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_port" {
  type = string
}

variable "django_secret_key" {
  type = string
}

variable "django_settings_module" {
  type = string
}

resource "ncloud_public_ip" "be" {
  server_instance_no = ncloud_server.be.instance_no
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

output "products" {
  value = {
    for product in data.ncloud_server_products.sm.server_products:
    product.id => product.product_name
  }
}

output "be_public_ip" {
  value = ncloud_public_ip.be.public_ip
}

## db
resource "ncloud_access_control_group" "db" {
  vpc_no      = ncloud_vpc.main.vpc_no
  name = "db-staging"
}

resource "ncloud_access_control_group_rule" "db" {
 access_control_group_no = ncloud_access_control_group.db.id

  inbound {
    protocol    = "TCP"
    ip_block    = "0.0.0.0/0"
    port_range  = "5432"
    description = "accept 5432 port for postgresql"
  }
}

resource "ncloud_network_interface" "db" {
    name                  = "db-nic"
    subnet_no             = ncloud_subnet.main.id
    access_control_groups = [
        ncloud_vpc.main.default_access_control_group_no,
        ncloud_access_control_group.db.id,
    ]
}

resource "ncloud_init_script" "db" {
  name    = "set-db-tf"
  content = templatefile("${path.module}/db_init_script.tftpl", {
    password = var.password
    db = var.db
    db_user = var.db_user
    db_password = var.db_password
    db_port = var.db_port
  })
}


resource "ncloud_server" "db" {
  subnet_no                 = ncloud_subnet.main.id
  name                      = "db-staging"
  server_image_product_code = "SW.VSVR.OS.LNX64.UBNTU.SVR2004.B050"
  server_product_code = data.ncloud_server_products.sm.server_products[0].product_code
  login_key_name            = ncloud_login_key.loginkey.key_name
  init_script_no = ncloud_init_script.db.init_script_no

  network_interface {
    network_interface_no = ncloud_network_interface.db.id
    order = 0
  }
}

resource "ncloud_public_ip" "db" {
  server_instance_no = ncloud_server.db.instance_no
}

output "db_public_ip" {
  value = ncloud_public_ip.db.public_ip
}

## LoadBalancer

# subnet
resource "ncloud_subnet" "be-lb" {
  vpc_no         = ncloud_vpc.main.id
  subnet         = cidrsubnet(ncloud_vpc.main.ipv4_cidr_block, 8, 2)
  zone           = "KR-2"
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "be-lb-subnet"
  usage_type     = "LOADB"
}

# LoadBalancer
resource "ncloud_lb" "be-staging" {
  name = "be-lb-staging"
  network_type = "PUBLIC"
  type = "NETWORK_PROXY"
  subnet_no_list = [ ncloud_subnet.be-lb.subnet_no ]
}

resource "ncloud_lb_listener" "be" {
  load_balancer_no = ncloud_lb.be-staging.load_balancer_no
  protocol = "TCP"
  port = 80
  target_group_no = ncloud_lb_target_group.be.target_group_no
}

# target group
resource "ncloud_lb_target_group" "be" {
  vpc_no   = ncloud_vpc.main.vpc_no
  protocol = "PROXY_TCP"
  target_type = "VSVR"
  port        = 8000
  description = "for django be"
  health_check {
    protocol = "TCP"
    http_method = "GET"
    port           = 8000
    url_path       = "/admin"
    cycle          = 30
    up_threshold   = 2
    down_threshold = 2
  }
  algorithm_type = "RR"
}

# target group attachment
resource "ncloud_lb_target_group_attachment" "be" {
  target_group_no = ncloud_lb_target_group.be.target_group_no
  target_no_list = [ncloud_server.be.instance_no]
}

output "lb_dns" {
  value = ncloud_lb.be-staging.domain
}