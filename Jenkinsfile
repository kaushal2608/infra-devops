pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = "true"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
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

            def ips = sh(
                script: "cd terraform && terraform output -json public_ips | jq -r '.[]'",
                returnStdout: true
            ).trim().split("\n")

            writeFile file: "ansible/inventory", text: """
[web]
${ips[0]} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/terraform.pem
${ips[1]} ansible_user=ubuntu ansible_ssh_private_key_file=/var/lib/jenkins/.ssh/terraform.pem
"""
        }

    }

}

        stage('Install Docker using Ansible') {
    steps {
        sh '''
        ANSIBLE_CONFIG=ansible/ansible.cfg \
        ansible-playbook \
        -i ansible/inventory \
        ansible/docker-install.yml
        '''
    }
}

    }
}