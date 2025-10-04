#!/bin/bash

# open ports for control plane
sudo ufw allow 6443
sudo ufw allow 2379:2380/tcp
sudo ufw allow 10250
sudo ufw allow 10256:10257/tcp
sudo ufw allow 10259
sudo ufw --force enable
sudo ufw status

# Installing kubectl and running kubeadm
# on the master node to create a cluster
sudo apt-get install -y kubectl
sudo apt-mark hold kubectl

# Need to run kubeadm with master ip address as control plane address.
sudo kubeadm init --control-plane-endpoint 192.168.60.11 --apiserver-advertise-address 192.168.60.11

# copy the kubeconfig to $HOME
sudo cp /etc/kubernetes/admin.conf /shared_data/kubeconfig.yaml
sudo chown $(id -u):$(id -g) /shared_data/kubeconfig.yaml

# Copy the join command to shared-folder
kubeadm token create --print-join-command > /shared_data/join.sh