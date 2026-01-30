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

# -------------------------------
# Docker socket mapping (CRITICAL)
# -------------------------------
if [[ "$(uname)" == "Linux" ]]; then
  DOCKER_MOUNT="/var/run/docker.sock:/var/run/docker.sock"
else
  # Windows (Docker Desktop + Git Bash)
  DOCKER_MOUNT="//./pipe/docker_engine:/var/run/docker.sock"
fi

echo "🔌 Docker socket mount: $DOCKER_MOUNT"

# Remove existing container if present
docker rm -f "$JENKINS_CONTAINER" >/dev/null 2>&1 || true

DOCKER_ENV="-e DOCKER_HOST=tcp://host.docker.internal:2375"

docker run -d \
  --name "$JENKINS_CONTAINER" \
  --user root \
  -p "$JENKINS_PORT:8080" \
  -v "$JENKINS_VOLUME:/var/jenkins_home" \
  -v "$HOME/.kube:/var/jenkins_home/.kube" \
  $DOCKER_ENV \
  "$JENKINS_IMAGE" >/dev/null

echo ""
echo "🌐 Jenkins is starting..."
echo "👉 Open Jenkins UI: http://localhost:$JENKINS_PORT"
echo ""
echo "ℹ️ If this is the first run, Jenkins will show the Unlock screen."
echo "ℹ️ Initial password appears once in Jenkins logs."
echo ""
echo "👉 Press 'q' to stop Jenkins"

# Wait for user input
while true; do
  read -r -n 1 key
  if [[ "$key" == "q" ]]; then
    cleanup
  fi
done
