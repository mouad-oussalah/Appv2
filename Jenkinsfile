pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh 'docker build --target base -t olympicplayers-app:${BUILD_NUMBER} .'
            }
        }

        stage('Test') {
            steps {
                sh 'docker build --target test -t olympicplayers-app-test:${BUILD_NUMBER} .'
                sh 'docker run --rm olympicplayers-app-test:${BUILD_NUMBER} pytest'
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker build --target production -t olympicplayers-app:${BUILD_NUMBER} .'
                // Add your deployment steps here
            }
        }
    }

    post {
        always {
            // Clean up Docker images
            sh 'docker rmi olympicplayers-app:${BUILD_NUMBER} olympicplayers-app-test:${BUILD_NUMBER}'
        }
    }
}