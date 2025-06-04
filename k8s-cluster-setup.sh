#!/bin/bash

set -e

### CONFIG ###
K8S_VERSION="1.29.0-00"


echo "🚧 Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Install dependencies if not already installed
if ! command -v kubeadm &> /dev/null; then
  echo "📦 Installing kubeadm, kubelet, kubectl..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

  echo "🔐 Adding Kubernetes GPG key..."
  sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "📦 Adding Kubernetes repo..."
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  echo "📦 Installing kubelet=${K8S_VERSION}, kubeadm=${K8S_VERSION}, kubectl=${K8S_VERSION}..."
  sudo apt-get update
  sudo apt-get install -y kubelet=${K8S_VERSION} kubeadm=${K8S_VERSION} kubectl=${K8S_VERSION}
  sudo apt-mark hold kubelet kubeadm kubectl
fi

# Install containerd if not already installed
if ! command -v containerd &> /dev/null; then
  echo "📦 Installing containerd..."
  sudo apt-get install -y containerd
  sudo mkdir -p /etc/containerd
  containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
  sudo systemctl restart containerd
  sudo systemctl enable containerd
fi

echo "🚀 Initializing Kubernetes control plane..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "🔧 Setting up kubeconfig for user: $USER"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "🌐 Installing Flannel CNI for networking..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait a bit for Flannel to initialize
echo "⏳ Waiting for Flannel to initialize..."
kubectl -n kube-system rollout status daemonset/kube-flannel-ds --timeout=180s || true


# Install openEBS for storage class
kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml

# Restart kubelet to ensure network plugin is recognized
echo "🔄 Restarting Kubelet..."
sudo systemctl restart kubelet

# Reload Kernel parameters
echo "🔄 Restarting containerd"
sudo systemctl restart containerd
sudo systemctl enable containerd

# Allow workloads on master node
echo "🪄 Allowing workloads on master node..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Verify Node Status
echo "📊 Checking Node status..."
kubectl get nodes

echo "✅ Kubernetes Cluster is Ready!"
