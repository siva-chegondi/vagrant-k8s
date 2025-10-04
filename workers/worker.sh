#!/bin/bash

sudo ufw allow 10250
sudo ufw allow 10256
sudo ufw allow 30000:32767/tcp
sudo ufw allow 30000:32767/udp
sudo ufw --force enable
sudo ufw status

# Run the join command from the k8s master
sudo bash /shared_data/join.sh