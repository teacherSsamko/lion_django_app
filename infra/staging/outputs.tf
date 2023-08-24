# output "lb_dns" {
#   value = ncloud_lb.be-staging.domain
# }

output "db_public_ip" {
  value = module.servers.db_public_ip
}

output "be_public_ip" {
  value = module.servers.be_public_ip
}
