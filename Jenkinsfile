pipeline {
  agent any
  stages {

    stage('Build Docker Images') {
      steps {
        sh '''
          echo "Building backend image"
          docker build --no-cache -t infra-health-backend:latest ./backend

          echo "Building frontend image"
          docker build --no-cache -t infra-health-frontend:latest ./frontend
        '''
      }
    }

    stage('Load Images into kind') {
      steps {
        sh '''
          echo "Loading images into kind cluster"
          kind load docker-image infra-health-backend:latest --name infra-health
          kind load docker-image infra-health-frontend:latest --name infra-health
        '''
      }
    }

    stage('Deploy to Kubernetes') {
      steps {
        sh '''
          echo "Restarting Kubernetes deployments"
          kubectl rollout restart deployment/backend -n infra-health
          kubectl rollout restart deployment/worker -n infra-health
          kubectl rollout restart deployment/frontend -n infra-health
        '''
      }
    }

  }
}
