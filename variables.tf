variable "owner" {}
variable "name" {}
variable "ttl" {}
variable "environment_tag" {}

variable "key_name" {}

variable "dns_domain" {}

variable "network_address_space" {}

variable "ssh_user" {}


locals {
  mod_az = "${length(split(",", join(", ",data.aws_availability_zones.available.names)))}"
}

variable "db_subnet_count" {}

variable "web_subnet_count" {}



