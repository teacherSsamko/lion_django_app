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