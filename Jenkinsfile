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
                    credentialsId: 'dockerhub-cred',
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
        echo "Starting new container for version ${IMAGE_TAG}"

        # Run new version on temporary port
        docker run -d \
          --name flask-app-${IMAGE_TAG} \
          -p 5001:5000 \
          $IMAGE_NAME:$IMAGE_TAG

        echo "Waiting for application startup..."
        sleep 10

        echo "Running health check on new version..."
        curl -f http://localhost:5001

        echo "Health check passed. Switching live traffic..."

        # Stop and remove old container ONLY
        docker stop flask-app || true
        docker rm flask-app || true

        # Stop temporary container
        docker stop flask-app-${IMAGE_TAG}
        docker rm flask-app-${IMAGE_TAG}

        # Start new container on live port
        docker run -d \
          --name flask-app \
          -p 5000:5000 \
          $IMAGE_NAME:$IMAGE_TAG

        echo "Deployment completed successfully"
        '''
    }
}
        
	stage('Cleanup Old Images') {
    when {
        expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
    }
    steps {
        sh '''
        echo "Cleaning up old Docker images, keeping last 3 versions..."

        IMAGE_NAME="sumanthkp4995/python-flask-app"

        # Get all tags sorted numerically (newest last)
        TAGS=$(docker images $IMAGE_NAME --format "{{.Tag}}" \
              | grep -E '^[0-9]+$' \
              | sort -n)

        # Count tags
        TAG_COUNT=$(echo "$TAGS" | wc -l)

        if [ "$TAG_COUNT" -le 3 ]; then
            echo "Only $TAG_COUNT image(s) found. Nothing to delete."
            exit 0
        fi

        # Calculate how many to remove
        REMOVE_COUNT=$((TAG_COUNT - 3))

        # Select oldest tags
        REMOVE_TAGS=$(echo "$TAGS" | head -n $REMOVE_COUNT)

        for TAG in $REMOVE_TAGS; do
            echo "Removing old image: $IMAGE_NAME:$TAG"
            docker rmi -f $IMAGE_NAME:$TAG || true
        done

        echo "Cleanup completed. Kept last 3 images."
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
