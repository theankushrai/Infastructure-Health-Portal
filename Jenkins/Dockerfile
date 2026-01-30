FROM jenkins/jenkins:lts

# IMPORTANT:
# We intentionally run Jenkins as root on Windows
# because Docker Desktop does NOT allow non-root
# access to /var/run/docker.sock reliably.

USER root

# Install OS tools
RUN apt-get update && apt-get install -y \
    docker.io \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -L -o kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/kubectl

# Install kind
RUN curl -L -o kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 && \
    chmod +x kind && \
    mv kind /usr/local/bin/kind

# NOTE:
# We do NOT switch back to USER jenkins
# Jenkins will run as root to access Docker socket
