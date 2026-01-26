#!/bin/bash

set -e

JENKINS_CONTAINER="infra-health-jenkins"
JENKINS_IMAGE="infra-health-jenkins"
JENKINS_VOLUME="infra-health-jenkins-data"
JENKINS_PORT=8081

cleanup() {
  echo ""
  echo "🛑 Stopping Jenkins..."
  docker stop "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  docker rm "$JENKINS_CONTAINER" >/dev/null 2>&1 || true
  echo "✅ Jenkins stopped"
  exit 0
}

# Handle Ctrl+C
trap cleanup SIGINT SIGTERM

echo "🚀 Starting Jenkins with persistence..."

# Build Jenkins image
docker build -t "$JENKINS_IMAGE" jenkins >/dev/null

# Detect Docker socket (Linux vs Windows)
if [[ "$(uname)" == "Linux" ]]; then
  DOCKER_SOCKET="/var/run/docker.sock"
else
  DOCKER_SOCKET="//./pipe/docker_engine"
fi

echo "🔌 Using Docker socket: $DOCKER_SOCKET"

# Remove existing container if present
docker rm -f "$JENKINS_CONTAINER" >/dev/null 2>&1 || true

# Run Jenkins
docker run -d \
  --name "$JENKINS_CONTAINER" \
  -p "$JENKINS_PORT:8080" \
  -v "$JENKINS_VOLUME:/var/jenkins_home" \
  -v "$DOCKER_SOCKET:$DOCKER_SOCKET" \
  -v "$HOME/.kube:/var/jenkins_home/.kube" \
  "$JENKINS_IMAGE" >/dev/null

echo ""
echo "🌐 Jenkins is starting..."
echo "👉 Open Jenkins UI: http://localhost:$JENKINS_PORT"
echo ""
echo "ℹ️ If this is the first run, Jenkins will show the Unlock screen."
echo "ℹ️ Password is printed in Jenkins logs (one-time only)."
echo ""
echo "👉 Press 'q' to stop Jenkins"

# Wait for user input
while true; do
  read -r -n 1 key
  if [[ "$key" == "q" ]]; then
    cleanup
  fi
done