pipeline {
    agent any

    environment {
        IMAGE_NAME = "sumanthkp4995/python-flask-app"
        IMAGE_TAG  = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/SumanthKP4995/pthon-docker-app'
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                docker build -t $IMAGE_NAME:$IMAGE_TAG .
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                }
            }
        }

        stage('Push Image') {
            steps {
                sh '''
                docker push $IMAGE_NAME:$IMAGE_TAG
                '''
            }
        }

        stage('Deploy Safely') {
            steps {
                sh '''
                echo "Starting new container version $IMAGE_TAG"

                docker run -d \
                  --name flask-app-$IMAGE_TAG \
                  -p 5001:5000 \
                  $IMAGE_NAME:$IMAGE_TAG

                echo "Waiting for app startup..."
                sleep 10

                echo "Health check..."
                curl -f http://localhost:5001

                echo "Promoting new version..."

                docker stop flask-app || true
                docker rm flask-app || true

                docker stop flask-app-$IMAGE_TAG
                docker rm flask-app-$IMAGE_TAG

                docker run -d \
                  --name flask-app \
                  -p 5000:5000 \
                  $IMAGE_NAME:$IMAGE_TAG
                '''
            }
        }
    }

    post {
        failure {
            echo "Deployment failed — old version still running"
        }
    }
}
