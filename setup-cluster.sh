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
    else
        echo "✅ Cluster is already present;"
    fi

    echo "🛠️ Detecting Kind API Port and patching Kubeconfig..."
    
    # Dynamically detect the port Docker assigned to Kind's API
    KIND_PORT=$(docker inspect --format='{{(index (index .NetworkSettings.Ports "6443/tcp") 0).HostPort}}' "${CONTROL_PLANE_NAME}")
    echo "🔍 Detected Kind is running on Host Port: $KIND_PORT"

    # Patch config with detected port and container name alias;
    sed -i "s/server: https:\/\/127.0.0.1:[0-9]*/server: https:\/\/${CONTROL_PLANE_NAME}:${KIND_PORT}/g" ~/.kube/config
    
    # Disable TLS verification for this context;
    kubectl config set-cluster "kind-${CLUSTER_NAME}" --insecure-skip-tls-verify=true
    
    echo "⏳ Waiting for API Server to respond at https://${CONTROL_PLANE_NAME}:${KIND_PORT}..."
    until kubectl cluster-info --insecure-skip-tls-verify >/dev/null 2>&1; do
        echo "⏳ API Server is still starting... (checking port $KIND_PORT)"
        sleep 3
    done
    echo "🚀 API Server is ONLINE;"
}

# --- EXECUTE STARTUP SEQUENCE ---
setup_hosts
install_dependencies
manage_cluster

# --- 4. PREPARE NAMESPACE ---
echo "📂 Preparing Namespace..."
kubectl --insecure-skip-tls-verify create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl --insecure-skip-tls-verify apply -f -
kubectl config set-context --current --namespace="$NAMESPACE"

# --- 5. BUILD & PIPE IMAGES (DIRECT STREAMING) ---
echo "📦 Building images and streaming to Kind (Pro Method)..."

# Build and stream Backend
docker build --no-cache -t infra-health-backend:latest ./backend
docker save infra-health-backend:latest | docker exec -i "${CONTROL_PLANE_NAME}" ctr -n k8s.io images import -

# Build and stream Frontend
docker build --no-cache -t infra-health-frontend:latest ./frontend
docker save infra-health-frontend:latest | docker exec -i "${CONTROL_PLANE_NAME}" ctr -n k8s.io images import -

echo "✅ Images loaded successfully via direct stream;"

# --- 6. INGRESS CONTROLLER SETUP ---
echo "🌐 Ensuring NGINX Ingress Controller is installed..."
kubectl --insecure-skip-tls-verify apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress Controller (This takes ~1-2 mins)..."
kubectl --insecure-skip-tls-verify wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# --- 7. APPLY APP MANIFESTS ---
echo "🚀 Applying K8s Manifests..."
kubectl --insecure-skip-tls-verify apply -f k8s/ -R 

echo ""
echo "✨ ALL SYSTEMS GO!"
echo "🔗 URL: http://$DOMAIN"
echo "🔧 Jenkins (if running): http://localhost:8081"