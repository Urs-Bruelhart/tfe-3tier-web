# INSTANCES

#resource "aws_key_pair" "aws_pub_key" {
#  key_name   = "aws-key"
#  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCvOp4xxCMWtSfMkO73Xv29aavZlPKFdJ3kI9CpY1Dnl0Q945TybNcFQuZ53RRvw7ccOx0CctuzDRwW3FX9rdD96htu2uoZXeeY0tB2gb3md/LpKw3I+PRJXIHwwbfpQK8rxXlmDIiPR8P7frNs/Y3z2dYxlmlE+OB4Y3hbF10vBxJUECX2AmTNDb+IBS1APJc/Sw+04aEwh2kiv5tfqhM+1bjhKxBzY/h5+H7jV0psH/TeAkr7yvY7KVwrqad+MXGvMfAwp0ziWh7BWMUeOHsCIJx9tUlLPL/5HvjeFniALXVIIrGo/kz1SI0Q5Na60iAETi1t8jlWOOPOWLe28JUL joern@Think-X1"
#}
resource "aws_instance" "jumphost" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.dmz_subnet.id}"
  private_ip                  = "${cidrhost(aws_subnet.dmz_subnet.cidr_block, 10)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.jumphost.id}"]
  #key_name                    = "${aws_key_pair.aws_pub_key.key_name}"
  key_name                    = "${var.key_name}"
  user_data = "${file("./templates/jumphost.sh")}"


  tags {
         Name = "jumphost"
         Environment = "${var.environment_tag}"
         TTL = "${var.ttl}"
  }
}


# DNS

data "aws_route53_zone" "selected" {
  name         = "${var.dns_domain}."
  private_zone = false
}

resource "aws_route53_record" "jumphost" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "${lookup(aws_instance.jumphost.*.tags[0], "Name")}"
  #name    = "jumphost"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jumphost.public_ip}"]
}

resource "null_resource" "get_key" {

      triggers {    
        always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
      command = "cat <<< ${var.id_rsa_aws} > id_rsa_aws.txt"
    }

}

resource "null_resource" "copy_key" {

  #depends_on = ["${null_resource.get_key}"]

  triggers {
    run_after_get_key = "${null_resource.get_key.id}"
  }
  provisioner "file" {
    source      = "id_rsa_aws.txt"
    destination = "~/.ssh/id_rsa"

    connection {
      type     = "ssh"
      host     = "${aws_instance.jumphost.public_ip}"
      user     = "${var.ssh_user}"
      private_key = "${var.id_rsa_aws}"
      insecure = true
    }
  }
}
