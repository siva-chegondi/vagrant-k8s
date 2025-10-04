#!/bin/bash

###### =================== #####
# Base script to make node ready
# for kubernetes cluster
###### =================== #####

# update machine
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

# disabling swap for all machines of k8s
sudo swapoff -a

# Updating linux kernel network settings for bridged traffic
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# Install the Container Runtime supporting CRI, containerd
sudo apt-get install -y containerd

# install key-rings to verify signature
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# install k8s repo to the apt
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install kubelet, kubeadm
# default bins required for provisioning a k8s cluster
sudo apt-get update
sudo apt-get install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

# enabling the kubelet service before running kubeadm
sudo systemctl enable --now kubelet

sudo ufw allow 22
sudo ufw --force enable