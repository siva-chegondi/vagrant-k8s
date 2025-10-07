#!/bin/bash

# Installing kubectl and running kubeadm
# on the master node to create a cluster
sudo apt-get install -y kubectl
sudo apt-mark hold kubectl

# Need to run kubeadm with master ip address as control plane address.
# Also skipping to install kube-proxy as cilium will handle this.
# Note: If you don't want to use cilium, please comment command from --skip-phases
sudo kubeadm init --control-plane-endpoint 192.168.60.11 --apiserver-advertise-address 192.168.60.11 --skip-phases=addon/kube-proxy

# copy the kubeconfig to $HOME
sudo cp /etc/kubernetes/admin.conf /shared_data/kubeconfig.yaml
sudo chown $(id -u):$(id -g) /shared_data/kubeconfig.yaml

# Copy the join command to shared-folder
kubeadm token create --print-join-command > /shared_data/join.sh