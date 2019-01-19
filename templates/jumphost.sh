#!/bin/bash
apt-get update -y
apt-get install -y ansible

echo "${var.id_rsa_aws}" > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/id_rsa
chown ubuntu /home/ubuntu/id_rsa
chgrp ubuntu /home/ubuntu/id_rsa

