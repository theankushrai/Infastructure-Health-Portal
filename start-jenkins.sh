#!/bin/bash

set -e

# --- CONFIGURATION ---
JENKINS_CONTAINER="infra-health-jenkins"
JENKINS_IMAGE="infra-health-jenkins"
JENKINS_VOLUME="infra-health-jenkins-data"
JENKINS_PORT=8081

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# UPDATED: Using Capital 'J' to match your folder name;
JENKINS_DOCKERFILE_DIR="$SCRIPT_DIR/Jenkins"

# --- 1. CLUSTER CHECK ---
echo "🔍 Checking Kubernetes cluster status..."

if ! kind get clusters | grep -q "infra-health"; then
    echo "❌ Cluster 'infra-health' not found;"
    echo "👉 Please run './setup-cluster.sh' first to configure your environment;"
    exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "⚠️  Cluster is configured but not responding;"
    echo "🔄 Attempting to restart Kind nodes..."
    docker start infra-health-control-plane >/dev/null 2>&1 || true
    sleep 5
fi

echo "✅ Cluster is up and running;"

# --- 2. JENKINS SETUP ---
cleanup() {
  echo ""
  echo "🛑 Stopping Jenkins..."
  docker stop "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  docker rm "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  echo "✅ Jenkins stopped;"
  exit 0
}

trap cleanup SIGINT SIGTERM

# Check if the Dockerfile directory exists
if [ ! -d "$JENKINS_DOCKERFILE_DIR" ]; then
    echo "❌ Error: Directory '$JENKINS_DOCKERFILE_DIR' not found;"
    echo "📂 I looked for it here: $JENKINS_DOCKERFILE_DIR;"
    echo "💡 Double-check the spelling and capitalization of your folder;"
    exit 1
fi

echo "🚀 Starting Jenkins in WSL mode..."

# Build Jenkins image
docker build -t "$JENKINS_IMAGE" "$JENKINS_DOCKERFILE_DIR" >/dev/null

DOCKER_MOUNT="/var/run/docker.sock:/var/run/docker.sock"

docker rm -f "$JENKINS_CONTAINER" >/dev/null 2>&1 || true

docker run -d \
  --name "$JENKINS_CONTAINER" \
  --user root \
  -p "$JENKINS_PORT:8080" \
  -v "$JENKINS_VOLUME:/var/jenkins_home" \
  -v "$HOME/.kube:/var/jenkins_home/.kube:ro" \
  -v "$DOCKER_MOUNT" \
  "$JENKINS_IMAGE" >/dev/null

echo ""
echo "🌐 Jenkins is starting..."
echo "👉 Open Jenkins UI: http://localhost:$JENKINS_PORT"
echo ""
echo "🔑 Initial Admin Password (wait a few seconds):"
for i in {1..15}; do
    PASS=$(docker exec "$JENKINS_CONTAINER" cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || true)
    if [ ! -z "$PASS" ]; then
        echo "------------------------------------------"
        echo "$PASS"
        echo "------------------------------------------"
        break
    fi
    sleep 2
done

echo ""
echo "👉 Press 'q' to stop Jenkins"

while true; do
  read -r -n 1 key
  if [[ "$key" == "q" ]]; then
    cleanup
  fi
done