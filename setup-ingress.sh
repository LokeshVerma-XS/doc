#!/bin/bash

set -e

### CONFIG ###
HELM_REPO="ingress-nginx"
HELM_CHART="ingress-nginx/ingress-nginx"
RELEASE_NAME="ingress-nginx"
NAMESPACE="ingress-nginx"

# Install Helm if not already installed
if ! command -v helm &> /dev/null; then
  echo "📦 Installing Helm..."
  curl -fsSL https://get.helm.sh/helm-v3.11.0-linux-amd64.tar.gz | tar xzv
  sudo mv linux-amd64/helm /usr/local/bin/helm
fi

# Add the NGINX Ingress Controller Helm repo if not already added
if ! helm repo list | grep -q "$HELM_REPO"; then
  echo "🔐 Adding Helm repository for Ingress NGINX..."
  helm repo add $HELM_REPO https://kubernetes.github.io/ingress-nginx
  helm repo update
fi

# Install the NGINX Ingress Controller using Helm
echo "🌐 Installing NGINX Ingress Controller with Helm..."
helm install $RELEASE_NAME $HELM_CHART --namespace $NAMESPACE --create-namespace --set controller.publishService.enabled=true

# Expose the NGINX Ingress Controller using NodePort
echo "🔧 Exposing NGINX Ingress Controller using NodePort..."
kubectl -n $NAMESPACE patch svc $RELEASE_NAME-controller -p '{"spec":{"type":"ClusterIP"}}'

echo "🔍 NGINX Ingress Controller exposed on NodePort. Access via <node-ip>:<node-port>."

# # Wait for the Ingress Controller to be ready
# echo "⌛ Waiting for NGINX Ingress Controller pods to be ready..."
# kubectl -n $NAMESPACE wait --for=condition=ready pod --all --timeout=300s

# Verify the Ingress Controller installation
kubectl get pods -n $NAMESPACE
kubectl get svc -n $NAMESPACE

echo "✅ NGINX Ingress Controller is installed and will be ready shortly!"
