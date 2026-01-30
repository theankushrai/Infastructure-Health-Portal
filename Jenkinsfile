pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                // Pulls the latest code from your repo;
                checkout scm;
            }
        }

        stage('Build Docker Images') {
            steps {
                sh '''
                    echo "Building backend image..."
                    docker build --no-cache -t infra-health-backend:latest ./backend

                    echo "Building frontend image..."
                    docker build --no-cache -t infra-health-frontend:latest ./frontend
                '''
            }
        }

        stage('Load Images into kind') {
            steps {
                sh '''
                    echo "Loading images into kind cluster: infra-health"
                    kind load docker-image infra-health-backend:latest --name infra-health
                    kind load docker-image infra-health-frontend:latest --name infra-health
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    # 1. Detect the internal IP to bypass Jenkins redirect loop;
                    echo "Detecting actual Kind Node IP..."
                    KIND_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' infra-health-control-plane)
                    echo "Kind is at: ${KIND_IP}"

                    # 2. Point to the config we injected via run-jenkins.sh;
                    # This stops the "Please enter Username: error: EOF" message;
                    export KUBECONFIG=/var/jenkins_home/.kube/config;

                    echo "Applying Kubernetes manifests via direct IP..."
                    kubectl --server="https://${KIND_IP}:6443" \
                            --insecure-skip-tls-verify \
                            apply -f k8s/ -R -n infra-health --validate=false
                    
                    echo "Restarting deployments to pick up the new images..."
                    kubectl --server="https://${KIND_IP}:6443" --insecure-skip-tls-verify rollout restart deployment/backend -n infra-health || true
                    kubectl --server="https://${KIND_IP}:6443" --insecure-skip-tls-verify rollout restart deployment/worker -n infra-health || true
                    kubectl --server="https://${KIND_IP}:6443" --insecure-skip-tls-verify rollout restart deployment/frontend -n infra-health || true
                    
                    echo "Waiting for rollout to complete..."
                    kubectl --server="https://${KIND_IP}:6443" --insecure-skip-tls-verify rollout status deployment/backend -n infra-health --timeout=60s || true
                '''
            }
        }
    }

    post {
        always {
            echo "Pipeline finished;"
        }
        success {
            echo "✅ Infrastructure Health Portal deployed successfully;"
        }
        failure {
            echo "❌ Deployment failed. Check the logs above;"
        }
    }
}