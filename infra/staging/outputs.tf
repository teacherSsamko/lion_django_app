output "lb_dns" {
  value = module.load_balancer.lb_dns
}

output "db_public_ip" {
  value = module.servers.db_public_ip
}

output "be_public_ip" {
  value = module.servers.be_public_ip
}
