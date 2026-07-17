pipeline {
    agent any

    environment {
        IMAGE_NAME = "kaushal2608/blog-platform"
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

       stage('Docker Login') {
    steps {
        withCredentials([usernamePassword(
            credentialsId: 'dockerhub-creds',
            usernameVariable: 'DOCKER_USER',
            passwordVariable: 'DOCKER_PASS'
        )]) {
            sh '''
                echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            '''
        }
    }
}

stage('Push Images') {
    steps {
        sh 'docker push $IMAGE_NAME-frontend:$IMAGE_TAG'
        sh 'docker push $IMAGE_NAME-backend:$IMAGE_TAG'
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