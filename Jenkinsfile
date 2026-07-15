pipeline {
    agent any

    stages {
        stage('Verify Tools') {
            steps {
                sh 'echo "Checking installed tools..."'
                sh 'terraform -version'
                sh 'ansible --version'
                sh 'docker --version'
                sh 'git --version'
            }
        }
    }
}
