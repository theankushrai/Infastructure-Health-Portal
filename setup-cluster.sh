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
    
    # Add Application Domain
    if ! grep -q "$DOMAIN" /etc/hosts; then
        echo "📝 Adding $DOMAIN to /etc/hosts (requires sudo)..."
        echo "127.0.0.1 $DOMAIN" | sudo tee -a /etc/hosts
    fi

    # NEW: Add Control Plane Alias so local terminal works with the "Pro Way"
    if ! grep -q "$CONTROL_PLANE_NAME" /etc/hosts; then
        echo "📝 Adding $CONTROL_PLANE_NAME to /etc/hosts..."
        echo "127.0.0.1 $CONTROL_PLANE_NAME" | sudo tee -a /etc/hosts
    fi
    echo "✅ Host entries verified;"
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
    elif [ "$(docker inspect -f '{{.State.Running}}' ${CONTROL_PLANE_NAME} 2>/dev/null)" == "false" ]; then
        echo "🛌 Cluster is present but STOPPED. Starting nodes..."
        docker start "${CONTROL_PLANE_NAME}"
        until kubectl cluster-info >/dev/null 2>&1; do
            echo "⏳ Waiting for API Server..."
            sleep 2
        done
    else
        echo "✅ Cluster is already UP and RUNNING;"
    fi

    echo "🛠️ Patching Kubeconfig for Jenkins & Local Terminal..."
    # Point server to the container name instead of 127.0.0.1;
    sed -i "s/server: https:\/\/127.0.0.1:[0-9]*/server: https:\/\/${CONTROL_PLANE_NAME}:6443/g" ~/.kube/config
    
    # NEW: Disable TLS verification globally for this cluster context so we don't need --insecure-skip-tls-verify every time locally;
    kubectl config set-cluster "kind-${CLUSTER_NAME}" --insecure-skip-tls-verify=true
    
    echo "✅ Kubeconfig tuned for container networking;"
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
echo "📦 Building images and loading to Kind..."

docker build --no-cache -t infra-health-backend:latest ./backend
kind load docker-image infra-health-backend:latest --name "$CLUSTER_NAME"

docker build --no-cache -t infra-health-frontend:latest ./frontend
kind load docker-image infra-health-frontend:latest --name "$CLUSTER_NAME"

# --- 6. INGRESS CONTROLLER SETUP ---
echo "🌐 Ensuring NGINX Ingress Controller is installed..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress Controller (This takes ~1-2 mins)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# --- 7. APPLY APP MANIFESTS ---
echo "🚀 Applying K8s Manifests..."
kubectl apply -f k8s/ -R 

echo ""
echo "✨ ALL SYSTEMS GO!"
echo "🔗 URL: http://$DOMAIN"
echo "🔧 Jenkins (if running): http://localhost:8081"