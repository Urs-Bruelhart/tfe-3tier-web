terraform {
  required_version = ">= 0.11.0"
}

provider "aws" {
}

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}
data "aws_ami" "nat_instance" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-hvm-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["137112412989"] # Amazon
}


# VPC 

resource "aws_vpc" "hashicorp_vpc" {
  cidr_block           = "${var.network_address_space}"
  enable_dns_hostnames = "true"

 
  tags {
         Name        = "${var.name}-vpc"
         Environment = "${var.environment_tag}"
         TTL         = "${var.ttl}"
         Owner       = "${var.owner}"
  }


}

# Internet Gateways and route table

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.hashicorp_vpc.id}"

}

resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.hashicorp_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }

    tags {
        Name        = "${var.name}-igw"
        Environment = "${var.environment_tag}"
    }

}

# nat route table

resource "aws_route_table" "rtb-nat" {
    vpc_id = "${aws_vpc.hashicorp_vpc.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags {
        Name = "${var.name}-nat_instance"
        Environment = "${var.environment_tag}"
    }
}

# public subnet to IGW

resource "aws_route_table_association" "dmz-subnet" {
  subnet_id      = "${aws_subnet.dmz_subnet.*.id[0]}"
  route_table_id = "${aws_route_table.rtb.id}"

}

# limit the amout of public web subnets to the amount of AZ
resource "aws_route_table_association" "pub_web-subnet" {
  count          = "${local.mod_az}"
  subnet_id      = "${element(aws_subnet.pub_web_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.rtb.id}"

}

# private subnet to NAT

resource "aws_route_table_association" "rtb-db" {
    count          = "${var.db_subnet_count}"
    subnet_id      = "${element(aws_subnet.db_subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.rtb-nat.id}"
}


resource "aws_route_table_association" "rtb-web" {
    count          = "${var.web_subnet_count}"
    subnet_id      = "${element(aws_subnet.web_subnet.*.id, count.index)}"
    route_table_id = "${aws_route_table.rtb-nat.id}"
}


# subnet public

resource "aws_subnet" "dmz_subnet" {
  vpc_id                  = "${aws_vpc.hashicorp_vpc.id}"
  cidr_block              = "${cidrsubnet(var.network_address_space, 8, 1)}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
          Name        = "dmz-subnet"
          Environment = "${var.environment_tag}"
          
  }

}


resource "aws_subnet" "pub_web_subnet" {
  count                   = "${local.mod_az}"
  cidr_block              = "${cidrsubnet(var.network_address_space, 8, count.index + 10)}"
  vpc_id                  = "${aws_vpc.hashicorp_vpc.id}"
  map_public_ip_on_launch = "true"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index % local.mod_az]}"

  tags {
          Name = "web-pub-subnet"
          Environment = "${var.environment_tag}"
  }

}

# subnet private


resource "aws_subnet" "db_subnet" {
  count                   = "${var.db_subnet_count}"
  vpc_id                  = "${aws_vpc.hashicorp_vpc.id}"
  cidr_block              = "${cidrsubnet(var.network_address_space, 8, count.index + 50)}"
  map_public_ip_on_launch = "false"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index % local.mod_az]}"

  tags {
          Name = "db-subnet"
          Environment = "${var.environment_tag}"
  }

}

resource "aws_subnet" "web_subnet" {
  count                   = "${var.web_subnet_count}"
  cidr_block              = "${cidrsubnet(var.network_address_space, 8, count.index + 20)}"
  vpc_id                  = "${aws_vpc.hashicorp_vpc.id}"
  map_public_ip_on_launch = "false"
  #availability_zone       = "${data.aws_availability_zones.available.names[count.index % local.mod_az]}"
  availability_zone       = "${data.aws_availability_zones.available.names[count.index % local.mod_az]}"

  tags {
          Name = "web-prv-subnet"
          Environment = "${var.environment_tag}"
  }

}


resource "aws_instance" "nat" {
  ami                         = "${data.aws_ami.nat_instance.id}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.dmz_subnet.id}"
  associate_public_ip_address = "true"
  vpc_security_group_ids      = ["${aws_security_group.nat.id}"]
  key_name                    = "${var.key_name}"
  source_dest_check           = false

  tags {
         Name        = "nat-instance"
         Environment = "${var.environment_tag}"
         TTL         = "${var.ttl}"
         Owner       = "${var.owner}"
  }

}
