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
