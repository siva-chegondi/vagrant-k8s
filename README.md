# Vagrant Kubernetes Lab (kubeadm + containerd)

This repository provisions a local, multi‑VM Kubernetes cluster using Vagrant and VirtualBox. It brings up:
- 1 control plane node (k8s-master) at 192.168.60.11
- 2 worker nodes (k8s-worker-1, k8s-worker-2) at 192.168.60.21 and 192.168.60.22

Provisioning uses kubeadm with containerd as the container runtime. A shared folder is used to pass the cluster join command and kubeconfig from the master to the host and workers. Optional Helm values are provided to deploy Cilium as the CNI.

## Stack / Technologies
- Vagrant (Vagrantfile based environment)
- VirtualBox provider
- Guest OS: Ubuntu 24.04 (box: bento/ubuntu-24.04, version pinned in Vagrantfiles)
- Kubernetes via kubeadm/kubelet/kubectl
- Container runtime: containerd
- Optional: Helm + Cilium (network/cilium-values.yaml)

## Requirements
- Host machine with:
  - VirtualBox (version 7.x recommended)
  - Vagrant (2.3+ recommended)
  - Internet access to download boxes and packages
- Recommended Vagrant plugin:
  - vagrant-vbguest (auto update is disabled in Vagrantfiles, but having the plugin can help ensure Guest Additions compatibility)
    - Install: `vagrant plugin install vagrant-vbguest`
- Optional tools on host:
  - kubectl (to interact with the cluster from the host using the exported kubeconfig)
  - helm (if you want to deploy Cilium using the provided values)

Notes:
- The Vagrantfiles configure a host-only private network on 192.168.60.0/24. Ensure this subnet is free on your host.
- The VMs are sized to master: 4GB RAM, 3 vCPUs; workers: 2GB RAM, 2 vCPUs each. Ensure your host has enough resources.

## Project Structure
- README.md — This document
- master/
  - Vagrantfile — Defines the k8s-master VM and provisioning
  - master.sh — Master provisioning: installs kubectl, runs `kubeadm init` (skips kube-proxy), writes kubeconfig and join command to shared folder
- workers/
  - Vagrantfile — Defines two worker VMs and provisioning
  - worker.sh — Worker provisioning: prepares a data disk at /data for Longhorn, installs iSCSI/NFS deps, runs the join command from shared folder
- k8s_node.sh — Base provisioning for all nodes (disable swap, sysctl for bridged traffic, install and configure containerd with systemd cgroups, install kubeadm/kubelet)
- data/
  - shared/
    - kubeconfig.yaml — Kubeconfig exported by the master for use by host and workers
    - join.sh — Kubeadm join command exported by the master
- network/
  - cilium.sh — Helper script to install Cilium via Helm using network/cilium-values.yaml
  - cilium-values.yaml — Example values for deploying Cilium (Gateway API, Envoy, Hubble, kube-proxy replacement)
- storage/
  - longhorn.sh — Helper script to label/annotate nodes and install Longhorn via Helm using storage/longhorn.yaml
  - longhorn.yaml — Minimal values (UI replicas, default replica count)

## How it Works
1. All nodes run the shared base script `k8s_node.sh` to prepare the OS and install kubeadm/kubelet/containerd.
2. The master runs `master/master.sh`:
   - Installs kubectl
   - Runs `kubeadm init --control-plane-endpoint 192.168.60.11 --apiserver-advertise-address 192.168.60.11 --skip-phases=addon/kube-proxy`
   - Writes `/shared_data/kubeconfig.yaml` and `/shared_data/join.sh` (these map to `data/shared` on the host)
3. Workers run `workers/worker.sh`:
   - Formats and mounts an extra disk at `/data` and installs storage dependencies for Longhorn (iSCSI, NFS)
   - Executes the join command from the shared folder to join the cluster

## Setup and Run
Run the master first, then the workers. Use separate shells or run sequentially.

1) Start the master
- cd master
- vagrant up

2) Start the workers (after master finished and exported join.sh)
- cd ../workers
- vagrant up

3) Verify cluster from the master VM
- vagrant ssh worker-1  # optional to check node
- vagrant ssh worker-2  # optional to check node
- cd ../master && vagrant ssh
- Inside master VM, you can run: `sudo kubectl get nodes`

4) Use the cluster from your host (optional)
- Export kubeconfig from repository root on your host:
  - `export KUBECONFIG=$(pwd)/data/shared/kubeconfig.yaml`
- Test: `kubectl get nodes`

Common Vagrant commands:
- Power off: `vagrant halt`
- Destroy and recreate: `vagrant destroy -f` then `vagrant up`
- SSH to a specific VM:
  - Master: `cd master && vagrant ssh`
  - Worker 1: `cd workers && vagrant ssh worker-1`
  - Worker 2: `cd workers && vagrant ssh worker-2`

## Optional: Install Cilium (CNI) via Helm
A sample Helm values file is provided at `network/cilium-values.yaml`.

Important: kubeadm does not install a CNI by default. The cluster needs a CNI plugin after init for full pod networking. You can deploy Cilium as follows from your host or the master VM once kubectl is configured:

- Install Helm if not present (on host or master VM):
  - Follow Helm install docs for your platform
- Run the following script to install the Cilium networking plugin:
  - `bash network/cilium.sh`
  - Note: Ensure `KUBECONFIG` is set to `$(pwd)/data/shared/kubeconfig.yaml` or that your kubectl context points at the lab cluster.

After Cilium is ready, verify node and pod networking:
- `kubectl -n kube-system get pods -l k8s-app=cilium`
- `kubectl get nodes -o wide`

## Optional: Install Longhorn (Storage)
Longhorn provides a distributed block storage for Kubernetes. The worker provisioning script already prepares a data disk at `/data` and installs required dependencies.

From your host or the master VM (with kubectl configured):
- Ensure Helm is installed.
- Ensure your kubectl is pointing at the lab cluster (e.g., export KUBECONFIG as shown above).
- Run the installer script:
  - `bash storage/longhorn.sh`

Verify Longhorn components:
- `kubectl -n longhorn-system get pods`

TODO: Document how to access the Longhorn UI service if needed.

## Scripts Summary
- k8s_node.sh
  - Disables swap; sets netfilter and IP forwarding sysctls
  - Installs and configures containerd (systemd cgroups, pause image), installs kubeadm and kubelet, enables kubelet
- master/master.sh
  - Installs kubectl
  - Runs kubeadm init referencing 192.168.60.11 and skips kube-proxy installation
  - Exports kubeconfig and join command to shared folder
- workers/worker.sh
  - Formats and mounts /dev/sdb to /data; installs iSCSI/NFS/crypto deps needed by Longhorn
  - Executes the exported join command
- network/cilium.sh
  - Adds Helm repo, installs Gateway API CRDs, installs Cilium with network/cilium-values.yaml
- network/cilium-values.yaml
  - Example configuration enabling Gateway API, Envoy, kube-proxy replacement and Hubble
- storage/longhorn.sh
  - Labels/annotates worker nodes for default Longhorn disk at /data and installs Longhorn with storage/longhorn.yaml
- storage/longhorn.yaml
  - Minimal Longhorn values (UI replicas, default replica count)

## Environment Variables
- None are required by the provisioning scripts.
- Optional: set `KUBECONFIG` on your host to point to `data/shared/kubeconfig.yaml` for kubectl access.

## Tests
- No automated tests are present in this repository.
- TODO: Add basic smoke tests (e.g., script that verifies nodes are Ready and can schedule a test pod).

## Troubleshooting
- Ensure the master VM finishes provisioning before bringing up workers (so `data/shared/join.sh` exists).
- If `vagrant up` fails to find a host-only network, adjust or free the 192.168.60.0/24 subnet in VirtualBox.
- If provisioning is slow or fails fetching packages, check your internet connectivity and any proxy settings.
- If kubectl cannot connect to the cluster from the host, ensure `KUBECONFIG=$(pwd)/data/shared/kubeconfig.yaml` is exported in your shell.
- If Helm commands fail, confirm Helm is installed and that your network can reach the Helm chart repositories.
- If Guest Additions–related shared folder issues occur, install the `vagrant-vbguest` plugin.

## License
- TODO: Add a LICENSE file and specify the project license.

## Acknowledgements
- Based on standard kubeadm workflow and Vagrant multi-machine patterns.
