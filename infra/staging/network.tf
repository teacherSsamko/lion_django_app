# resource "ncloud_subnet" "be-lb" {
#   vpc_no         = ncloud_vpc.main.id
#   subnet         = cidrsubnet(ncloud_vpc.main.ipv4_cidr_block, 8, 2)
#   zone           = "KR-2"
#   network_acl_no = ncloud_vpc.main.default_network_acl_no
#   subnet_type    = "PRIVATE"
#   name           = "be-lb-subnet"
#   usage_type     = "LOADB"
# }
