#!/bin/bash

# formatting the storage disk to ext4
# and mounting it to /data path
sudo mkfs.ext4 /dev/sdb
sudo mkdir -p /data
sudo mount /dev/sdb /data

# required on worker nodes for longhorn
sudo systemctl enable iscsid
sudo systemctl start iscsid
sudo apt-get install -y nfs-common cryptsetup dmsetup

# Run the join command from the k8s master
sudo bash /shared_data/join.sh