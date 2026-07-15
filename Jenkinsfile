pipeline {
    agent any
    options {
    skipDefaultCheckout(true)
}

    environment {
        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }
      stage('Check Changes') {
    steps {
        script {

            def changedFiles = sh(
                script: "git diff --name-only HEAD~1 HEAD",
                returnStdout: true
            ).trim()

            echo "Changed Files:"
            echo changedFiles

            if (!(changedFiles =~ /^terraform\//) &&
                !(changedFiles =~ /^ansible\//) &&
                !(changedFiles =~ /^Jenkinsfile$/)) {

                currentBuild.result = "NOT_BUILT"
                error("No Infrastructure changes detected.")
            }
        }
    }
}
        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Generate Inventory') {
            steps {
                script {
                    def ip = sh(
                        script: "cd terraform && terraform output -raw public_ip",
                        returnStdout: true
                    ).trim()

                    sh """
                    sed -i 's/SERVER_IP/${ip}/g' ansible/inventory
                    """
                }
            }
        }

        stage('Install Docker using Ansible') {
            steps {
                sh '''
                ansible-playbook \
                -i ansible/inventory \
                ansible/docker-install.yml
                '''
            }
        }

    }
}