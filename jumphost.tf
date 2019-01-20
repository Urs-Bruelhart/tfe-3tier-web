# INSTANCES


resource "aws_instance" "jumphost" {
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.dmz_subnet.id}"
  private_ip                  = "${cidrhost(aws_subnet.dmz_subnet.cidr_block, 10)}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.jumphost.id}"]
  key_name                    = "${var.key_name}"
  
    user_data = <<-EOF
              #!/bin/bash
              echo "${var.id_rsa_aws}" >> /home/ubuntu/.ssh/id_rsa
              chown ubuntu /home/ubuntu/.ssh/id_rsa
              chgrp ubuntu /home/ubuntu/.ssh/id_rsa
              chmod 600 /home/ubuntu/.ssh/id_rsa
              apt-get update -y
              apt-get install ansible -y 
              EOF

    tags {
         Name        = "jumphost"
         Environment = "${var.environment_tag}"
         TTL         = "${var.ttl}"
         Owner       = "${var.owner}"
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

#resource "null_resource" "get_key" {
#
#      triggers {    
#        always_run = "${timestamp()}"
#  }
#
#  provisioner "local-exec" {
#      command = "echo ${var.id_rsa_aws} >> id_rsa_aws.txt"
#    }
#
#}
#
#resource "null_resource" "copy_key" {
#
#  #depends_on = ["${null_resource.get_key}"]
#
#  triggers {
#    run_after_get_key = "${null_resource.get_key.id}"
#  }
#  provisioner "file" {
#    source      = "id_rsa_aws.txt"
#    destination = "~/.ssh/id_rsa"
#
#    connection {
#      type     = "ssh"
#      host     = "${aws_instance.jumphost.public_ip}"
#      user     = "${var.ssh_user}"
#      private_key = "${var.id_rsa_aws}"
#      insecure = true
#    }
#  }
#}
