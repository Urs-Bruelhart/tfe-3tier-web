variable "owner" {}
variable "name" {}
variable "ttl" {}
variable "environment_tag" {}
 
variable "key_name" {}

variable "id_rsa_aws" {}

variable "dns_domain" {
    default = "joestack.xyz"
}

variable "network_address_space" {
    default = "192.168.0.0/16"
}

variable "ssh_user" {
    default = "ubuntu"
}


locals {
  mod_az = "${length(split(",", join(", ",data.aws_availability_zones.available.names)))}"
}

variable "db_subnet_count" {
    default = "2"
}

variable "db_node_count" {
  default = "2"
}


variable "web_subnet_count" {
    default = "2"
}

variable "web_node_count" {
  default = "2"
}


variable "instance_type" {
  default = "t2.small"
}





