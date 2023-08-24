output "db_public_ip" {
  value = ncloud_public_ip.db.public_ip
}

output "be_public_ip" {
  value = ncloud_public_ip.be.public_ip
}

output "be_instance_no" {
  value = ncloud_server.be.instance_no
}
