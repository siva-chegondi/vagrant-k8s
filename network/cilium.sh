#!/bin/bash

# Add cilium repo
helm repo add cilium https://helm.cilium.io
helm repo update

# install gateway api CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.3.0/standard-install.yaml

# install cilium 1.17.6 to the cluster with custom configuration
# don't forgot to set $KUBECONFIG before running this
helm upgrade --install cilium cilium/cilium --version 1.17.6 --namespace kube-system -f $(dirname $0)/cilium-values.yaml
