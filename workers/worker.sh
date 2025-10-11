#!/bin/bash

# formatting the storage disk to ext4
# and mounting it to /data path
if [ -b /dev/sdb ] && ! blkid /dev/sdb; then
  # if /dev/sdb is not mounted ( not a boot disk )
  sudo mkfs.ext4 /dev/sdb
  sudo mkdir -p /data
  sudo mount /dev/sdb /data
else
  # if /dev/sdb is mounted ( boot disk )
  sudo mkfs.ext4 /dev/sda
  sudo mkdir -p /data
  sudo mount /dev/sda /data
fi

# required on worker nodes for longhorn
sudo systemctl enable iscsid
sudo systemctl start iscsid
sudo apt-get install -y nfs-common cryptsetup dmsetup

# Run the join command from the k8s master
sudo bash /shared_data/join.sh