#!/bin/bash

# Exit on error
set -e

CLUSTER_NAME="infra-health"
NAMESPACE="infra-health"
DOMAIN="infra-health.local"

# --- 1. HOSTS FILE INJECTION ---
setup_hosts() {
    echo "🌐 Checking /etc/hosts for $DOMAIN..."
    if grep -q "$DOMAIN" /etc/hosts; then
        echo "✅ Host entry already exists;"
    else
        echo "📝 Adding $DOMAIN to /etc/hosts (requires sudo)..."
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    fi
}

# --- 2. DEPENDENCY CHECK & INSTALL ---
install_dependencies() {
    echo "🔍 Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        echo "📥 Installing Docker..."
        sudo apt-get update && sudo apt-get install -y docker.io
        sudo usermod -aG docker $USER
    fi

    if ! command -v kubectl &> /dev/null; then
        echo "📥 Installing kubectl..."
        K8S_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
        sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm kubectl
    fi

    if ! command -v kind &> /dev/null; then
        echo "📥 Installing Kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.26.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
}

# --- 3. INTELLIGENT CLUSTER LIFECYCLE ---
manage_cluster() {
    echo "🚀 Managing Cluster: $CLUSTER_NAME..."
    
    # Check if Docker service is running (Essential for WSL)
    if ! docker info >/dev/null 2>&1; then
        echo "🐳 Docker service is down. Starting Docker..."
        sudo service docker start
        sleep 2
    fi

    if ! kind get clusters | grep -q "^$CLUSTER_NAME$"; then
        echo "🏗️ Cluster NOT FOUND. Building new cluster..."
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
    elif [ "$(docker inspect -f '{{.State.Running}}' ${CLUSTER_NAME}-control-plane 2>/dev/null)" == "false" ]; then
        echo "🛌 Cluster is present but STOPPED. Starting nodes..."
        docker start "${CLUSTER_NAME}-control-plane"
        until kubectl cluster-info >/dev/null 2>&1; do
            echo "⏳ Waiting for API Server..."
            sleep 2
        done
    else
        echo "✅ Cluster is already UP and RUNNING;"
    fi
}

# --- EXECUTE STARTUP SEQUENCE ---
setup_hosts
install_dependencies
manage_cluster

# --- 4. PREPARE NAMESPACE ---
echo "📂 Preparing Namespace..."
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
kubectl config set-context --current --namespace="$NAMESPACE"

# --- 5. BUILD & PIPE IMAGES ---
echo "📦 Building images and loading to Kind (Direct Pipe)..."

docker build --no-cache -t infra-health-backend:latest ./backend
docker save infra-health-backend:latest | docker exec -i "${CLUSTER_NAME}-control-plane" ctr -n k8s.io images import -

docker build --no-cache -t infra-health-frontend:latest ./frontend
docker save infra-health-frontend:latest | docker exec -i "${CLUSTER_NAME}-control-plane" ctr -n k8s.io images import -

# --- 6. INGRESS CONTROLLER SETUP ---
echo "🌐 Ensuring NGINX Ingress Controller is installed..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress Controller to be ready (Timeout: 5m)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# --- 7. APPLY APP MANIFESTS ---
echo "🚀 Applying K8s Manifests..."
kubectl apply -f k8s/mongo/
kubectl apply -f k8s/backend/
kubectl apply -f k8s/worker/
kubectl apply -f k8s/frontend/
kubectl apply -f k8s/ingress/

echo ""
echo "✨ ALL SYSTEMS GO!"
echo "🔗 URL: http://$DOMAIN"