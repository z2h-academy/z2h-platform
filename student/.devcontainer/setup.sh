#!/usr/bin/env bash
set -e

echo "=== Instalando dependencias mínimas ==="
sudo apt-get update
sudo apt-get install -y curl

echo "=== Instalando kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "=== Instalando k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

echo "=== Creando cluster k3d z2h ==="
k3d cluster create z2h \
  --servers 1 \
  --agents 1 \
  --port "8080:80@loadbalancer"

echo "=== Cluster creado exitosamente ==="
kubectl get nodes
