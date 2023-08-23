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

resource "ncloud_subnet" "be-lb" {
  vpc_no         = ncloud_vpc.main.id
  subnet         = cidrsubnet(ncloud_vpc.main.ipv4_cidr_block, 8, 2)
  zone           = "KR-2"
  network_acl_no = ncloud_vpc.main.default_network_acl_no
  subnet_type    = "PRIVATE"
  name           = "be-lb-subnet"
  usage_type     = "LOADB"
}

resource "ncloud_public_ip" "be" {
  server_instance_no = ncloud_server.be.instance_no
}

resource "ncloud_public_ip" "db" {
  server_instance_no = ncloud_server.db.instance_no
}
