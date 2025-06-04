#!/bin/bash

set -e

echo "🔧 Tearing down Kubernetes cluster..."

# Reset Kubernetes
sudo kubeadm reset -f

# Clean up configurations and data
echo "🧹 Removing Kubernetes configurations..."
sudo rm -rf /etc/kubernetes /var/lib/etcd /etc/cni/net.d
sudo rm -rf $HOME/.kube

# Remove swap entry
echo "🧹 Removing swap entry..."
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "💥 Kubernetes cluster teardown is complete!"
