pipeline {
    agent any

    environment {
        IMAGE_NAME = "YOUR_DOCKERHUB_USERNAME/blog-platform"
        IMAGE_TAG = "latest"
    }

    stages {

        stage('Clone') {
            steps {
                checkout scm
            }
        }

        stage('Build Frontend') {
            steps {
                sh 'docker build -t $IMAGE_NAME-frontend:$IMAGE_TAG ./frontend'
            }
        }

        stage('Build Backend') {
            steps {
                sh 'docker build -t $IMAGE_NAME-backend:$IMAGE_TAG ./backend'
            }
        }

        stage('Push Images') {
            steps {
                withDockerRegistry([credentialsId: 'dockerhub-creds']) {
                    sh 'docker push $IMAGE_NAME-frontend:$IMAGE_TAG'
                    sh 'docker push $IMAGE_NAME-backend:$IMAGE_TAG'
                }
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                docker compose down || true
                docker compose up -d --build
                '''
            }
        }
    }
}