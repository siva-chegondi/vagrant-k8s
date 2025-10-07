#!/bin/bash

## prepare the nodes for longhorn storage by adding node labels.
kubectl label nodes --overwrite k8s-worker-1 k8s-worker-2 node.longhorn.io/create-default-disk=config
kubectl annotate nodes --overwrite k8s-worker-1 k8s-worker-2 node.longhorn.io/default-disks-config='[{"path": "/data", "allowScheduling": true}]'

### installing the longhorn using helm charts

# add helm repo and update repos
helm repo add longhorn https://charts.longhorn.io
helm repo update

# installing the longhorn under the longhorn-system namespace
helm upgrade --install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.10.0 -f $(dirname $0)/longhorn.yaml
