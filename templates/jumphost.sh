#!/bin/bash
apt-get update -y
apt-get install -y ansible
echo "${var.id_rsa_aws}" >> xxx.txt