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

### configure the containerd runtime to enable systemd cgroups
### tell Containerd to use systemd cgroups

# copy the default config
sudo mkdir -p /etc/containerd/
sudo touch /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml # create with root prev
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo sed -i 's/pause:3.8/pause:3.10.1/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# install key-rings to verify signature
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# install k8s repo to the apt
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install kubelet, kubeadm
# default bins required for provisioning a k8s cluster
sudo apt-get update
sudo apt-get install -y kubelet kubeadm
sudo apt-mark hold kubelet kubeadm

sudo systemctl enable --now kubelet