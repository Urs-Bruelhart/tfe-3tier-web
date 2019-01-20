resource "aws_instance" "web_nodes" {
  count                       = "${var.web_node_count}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${element(aws_subnet.web_subnet.*.id, count.index + 1)}"
  associate_public_ip_address = "false"
  vpc_security_group_ids      = ["${aws_security_group.web.id}"]
  key_name                    = "${var.key_name}"
  

  tags {
         Name        = "${format("web-%02d", count.index + 1)}"
         Environment = "${var.environment_tag}"
         TTL         = "${var.ttl}"
         Owner       = "${var.owner}"
  }

}


resource "aws_instance" "db_nodes" {
  count                       = "${var.db_node_count}"
  ami                         = "${data.aws_ami.ubuntu.id}"
  instance_type               = "${var.instance_type}"
  subnet_id                   = "${element(aws_subnet.db_subnet.*.id, count.index + 1)}"
  associate_public_ip_address = "false"
  vpc_security_group_ids      = ["${aws_security_group.db.id}"]
  key_name                    = "${var.key_name}"
  

  tags {
         Name        = "${format("db-%02d", count.index + 1)}"
         Environment = "${var.environment_tag}"
         TTL         = "${var.ttl}"
         Owner       = "${var.owner}"
  }

}
