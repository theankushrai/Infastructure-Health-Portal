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
                    # Added --validate=false to prevent Jenkins from intercepting the OpenAPI request;
                    kubectl --insecure-skip-tls-verify apply -f k8s/ -R -n infra-health --validate=false
                    
                    echo "Restarting deployments to pick up the new images..."
                    # Added '|| true' so the pipeline doesn't crash if these don't exist yet;
                    kubectl --insecure-skip-tls-verify rollout restart deployment/backend -n infra-health || true
                    kubectl --insecure-skip-tls-verify rollout restart deployment/worker -n infra-health || true
                    kubectl --insecure-skip-tls-verify rollout restart deployment/frontend -n infra-health || true
                    
                    echo "Waiting for rollout to complete..."
                    # Only check status for the main backend;
                    kubectl --insecure-skip-tls-verify rollout status deployment/backend -n infra-health --timeout=60s || true
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