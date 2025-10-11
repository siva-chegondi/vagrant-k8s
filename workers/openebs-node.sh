#!/bin/bash

# setting the huge_pages for the node, kubelet restart is required.
echo 1024 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
echo vm.nr_hugepages = 1024 | sudo tee -a /etc/sysctl.conf
# required to update at kernel
sudo sysctl -p
# kubelet will read latest huge_pages data
sudo systemctl restart kubelet