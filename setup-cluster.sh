#!/bin/bash

# Exit on error
set -e

CLUSTER_NAME="infra-health"
NAMESPACE="infra-health"
DOMAIN="infra-health.local"
CONTROL_PLANE_NAME="${CLUSTER_NAME}-control-plane"

# --- 1. HOSTS FILE INJECTION ---
setup_hosts() {
    echo "🌐 Checking /etc/hosts for $DOMAIN and cluster alias..."
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "📝 Adding $DOMAIN to /etc/hosts (requires sudo)..."
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    fi
    if ! grep -q "$CONTROL_PLANE_NAME" /etc/hosts; then
        echo "📝 Adding $CONTROL_PLANE_NAME to /etc/hosts..."
        echo "127.0.0.1 $CONTROL_PLANE_NAME" | sudo tee -a /etc/hosts
    fi
}

# --- 2. DEPENDENCY CHECK ---
install_dependencies() {
    echo "🔍 Checking dependencies..."
    for cmd in docker kubectl kind; do
        if ! command -v $cmd &> /dev/null; then
            echo "❌ $cmd is missing. Please install it;"
            exit 1
        fi
    done
}

# --- 3. CLUSTER LIFECYCLE ---
manage_cluster() {
    if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
        echo "🏗️ Building new cluster..."
        cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
    else
        docker start "${CONTROL_PLANE_NAME}" 2>/dev/null || true
    fi

    # Patch Kubeconfig for local use
    KIND_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "6443/tcp") 0).HostPort}}' "${CONTROL_PLANE_NAME}")
    sed -i "s/server: https:\/\/127.0.0.1:[0-9]*/server: https:\/\/${CONTROL_PLANE_NAME}:${KIND_PORT}/g" ~/.kube/config
    kubectl config set-cluster "kind-${CLUSTER_NAME}" --insecure-skip-tls-verify=true
}

# --- EXECUTE ---
setup_hosts
install_dependencies
manage_cluster

# Prepare Namespace
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Ingress Setup
echo "🌐 Ensuring Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=300s

echo "✨ Cluster Ready;"