#!/bin/bash

# adding k8s-worker-3 node for openebs storage
kubectl label node --overwrite k8s-worker-1 k8s-worker-2 k8s-worker-3 openebs.io/engine=mayastor

# add openebs charts to helm repo
helm repo add openebs https://openebs.github.io/openebs
helm repo update

# install the openebs repo to k8s
helm upgrade --install openebs --namespace openebs openebs/openebs --create-namespace -f $(dirname $0)/openebs.yaml
