output "lb_dns" {
  value = ncloud_lb.be-staging.domain
}

output "db_public_ip" {
  value = ncloud_public_ip.db.public_ip
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