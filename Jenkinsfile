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
                    # This moves images from Docker into the Kind nodes;
                    kind load docker-image infra-health-backend:latest --name infra-health
                    kind load docker-image infra-health-frontend:latest --name infra-health
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    echo "Applying Kubernetes manifests..."
                    # Added '-n infra-health' to ensure it hits the right namespace;
                    kubectl --insecure-skip-tls-verify apply -f k8s/ -R -n infra-health
                    
                    echo "Restarting deployments to pick up the new images..."
                    kubectl --insecure-skip-tls-verify rollout restart deployment/backend -n infra-health
                    kubectl --insecure-skip-tls-verify rollout restart deployment/worker -n infra-health
                    kubectl --insecure-skip-tls-verify rollout restart deployment/frontend -n infra-health
                    
                    echo "Waiting for rollout to complete..."
                    kubectl --insecure-skip-tls-verify rollout status deployment/backend -n infra-health --timeout=60s
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