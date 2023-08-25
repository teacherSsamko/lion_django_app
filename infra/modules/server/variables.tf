variable "NCP_ACCESS_KEY" {
  type = string
}

variable "NCP_SECRET_KEY" {
  type      = string
  sensitive = true
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "name" {
  type = string
}

variable "init_script_path" {
  type = string
}

variable "init_script_envs" {
  type = map(any)
}

variable "server_product_code" {
  type = string
}

variable "acg_port_range" {
  type = string
}
