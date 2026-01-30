#!/bin/bash

set -e

# --- CONFIGURATION ---
JENKINS_CONTAINER="infra-health-jenkins"
JENKINS_IMAGE="infra-health-jenkins"
JENKINS_VOLUME="infra-health-jenkins-data"
JENKINS_PORT=8081
CLUSTER_NAME="infra-health"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JENKINS_DOCKERFILE_DIR="$SCRIPT_DIR/Jenkins"

# --- 1. CLUSTER CHECK ---
echo "🔍 Checking Kubernetes cluster status..."

if ! kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "❌ Cluster '$CLUSTER_NAME' not found;"
    echo "👉 Please run './setup-cluster.sh' first;"
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "⚠️ Cluster not responding. Attempting restart..."
    docker start "${CLUSTER_NAME}-control-plane" >/dev/null 2>&1 || true
    sleep 2
fi

echo "✅ Cluster is up;"

# --- 2. JENKINS SETUP ---
cleanup() {
  echo -e "\n🛑 Stopping Jenkins..."
  docker stop "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  docker rm "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  echo "✅ Jenkins stopped;"
  exit 0
}

trap cleanup SIGINT SIGTERM

echo "🚀 Starting Jenkins..."

# Build Jenkins image
docker build -t "$JENKINS_IMAGE" "$JENKINS_DOCKERFILE_DIR" >/dev/null

DOCKER_MOUNT="/var/run/docker.sock:/var/run/docker.sock"

docker rm -f "$JENKINS_CONTAINER" >/dev/null 2>&1 || true

# Start Jenkins
docker run -d \
  --name "$JENKINS_CONTAINER" \
  --user root \
  -p "$JENKINS_PORT:8080" \
  -v "$JENKINS_VOLUME:/var/jenkins_home" \
  -v "$DOCKER_MOUNT" \
  "$JENKINS_IMAGE" >/dev/null

# --- 3. NETWORK BRIDGE (THE FIX) ---
echo "🔗 Connecting Jenkins to the Kind network bridge..."
# This allows Jenkins to 'see' the 172.18.x.x IP range of the cluster;
docker network connect kind "$JENKINS_CONTAINER" 2>/dev/null || true

# --- 4. INJECT KUBECONFIG ---
echo "🔑 Syncing Kubeconfig..."
docker exec -u root "$JENKINS_CONTAINER" mkdir -p /var/jenkins_home/.kube
docker cp "$HOME/.kube/config" "$JENKINS_CONTAINER:/var/jenkins_home/.kube/config"
docker exec -u root "$JENKINS_CONTAINER" chown -R jenkins:jenkins /var/jenkins_home/.kube
echo "✅ Credentials and Bridge ready;"



echo "----------------------------------------------------------"
echo "🌐 Jenkins UI: http://localhost:$JENKINS_PORT"
echo "🔑 If this is your first run, get the admin password with:"
echo "   docker exec $JENKINS_CONTAINER cat /var/jenkins_home/secrets/initialAdminPassword"
echo "----------------------------------------------------------"

echo "👉 Press 'q' to stop Jenkins"

while true; do
  read -r -n 1 key
  if [[ "$key" == "q" ]]; then
    cleanup
  fi
done