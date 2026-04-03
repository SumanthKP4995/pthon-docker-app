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

        /* ✅ LOCAL DOCKER CLEANUP (JENKINS SERVER ONLY) */
        stage('Cleanup Local Docker Images (Keep Last 3)') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh '''
                echo "Cleaning local Docker images, keeping last 3..."

                TAGS=$(docker images $IMAGE_NAME --format "{{.Tag}}" \
                      | grep -E '^[0-9]+$' \
                      | sort -n)

                COUNT=$(echo "$TAGS" | wc -l)

                if [ "$COUNT" -le 3 ]; then
                    echo "Nothing to clean"
                    exit 0
                fi

                REMOVE_COUNT=$((COUNT - 3))
                REMOVE_TAGS=$(echo "$TAGS" | head -n $REMOVE_COUNT)

                for TAG in $REMOVE_TAGS; do
                    echo "Removing local image $IMAGE_NAME:$TAG"
                    docker rmi -f $IMAGE_NAME:$TAG || true
                done
                '''
            }
        }

        /* ✅ DOCKER HUB CLEANUP (REGISTRY) */
        stage('Cleanup Docker Hub Tags (Keep Last 3)') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                withCredentials([string(
                    credentialsId: 'dockerhub-api-token',
                    variable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''#!/bin/bash
                    set -e

                    USERNAME="sumanthkp4995"
                    REPO="python-flask-app"
                    KEEP=3

                    echo "Fetching tags from Docker Hub..."

                    TAGS=$(curl -s -H "Authorization: Bearer $DOCKERHUB_TOKEN" \
                      "https://hub.docker.com/v2/repositories/$USERNAME/$REPO/tags/?page_size=100" \
                      | grep -o '"name":"[0-9]*"' \
                      | cut -d':' -f2 | tr -d '"' \
                      | sort -n)

                    TOTAL=$(echo "$TAGS" | wc -l)

                    if [ "$TOTAL" -le "$KEEP" ]; then
                        echo "Nothing to delete from Docker Hub"
                        exit 0
                    fi

                    DELETE_COUNT=$((TOTAL - KEEP))
                    DELETE_TAGS=$(echo "$TAGS" | head -n $DELETE_COUNT)

                    for TAG in $DELETE_TAGS; do
                        echo "Deleting Docker Hub tag: $TAG"
                        curl -s -X DELETE \
                          -H "Authorization: Bearer $DOCKERHUB_TOKEN" \
                          "https://hub.docker.com/v2/repositories/$USERNAME/$REPO/tags/$TAG/"
                    done

                    echo "Docker Hub cleanup completed"
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed — no images were removed from Docker Hub"
        }
    }
}
