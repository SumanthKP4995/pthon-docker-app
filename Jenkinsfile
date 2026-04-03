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
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
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

        /* ✅ RUN ONLY LATEST CONTAINER */
        stage('Deploy Latest Container on Local Server') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh '''
                echo "Deploying latest container (build $IMAGE_TAG)..."

                docker stop flask-app || true
                docker rm flask-app || true

                docker run -d \
                  --name flask-app \
                  --restart unless-stopped \
                  -p 5000:5000 \
                  $IMAGE_NAME:$IMAGE_TAG

                echo "Latest container is running"
                '''
            }
        }

        /* ✅ LOCAL IMAGE CLEANUP (KEEP LAST 3) */
        stage('Cleanup Local Docker Images (Keep Last 3)') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                sh '''
                echo "Cleaning local Docker images..."

                TAGS=$(docker images $IMAGE_NAME --format "{{.Tag}}" \
                  | grep -E '^[0-9]+$' | sort -n)

                COUNT=$(echo "$TAGS" | wc -l)

                if [ "$COUNT" -le 3 ]; then
                    echo "Nothing to clean locally"
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

        /* ✅ DOCKER HUB CLEANUP (KEEP LAST 3 TAGS) */
        stage('Cleanup Docker Hub Tags (Keep Last 3)') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-cred',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''#!/bin/bash
                    set +e

                    REPO="python-flask-app"
                    KEEP=3

                    JWT=$(curl -s -X POST https://hub.docker.com/v2/users/login/ \
                      -H "Content-Type: application/json" \
                      -d '{"username":"'"$DOCKERHUB_USER"'","password":"'"$DOCKERHUB_TOKEN"'"}' \
                      | jq -r .token)

                    if [ -z "$JWT" ] || [ "$JWT" = "null" ]; then
                        echo "Docker Hub auth failed. Skipping cleanup."
                        exit 0
                    fi

                    TAGS=$(curl -s -H "Authorization: JWT $JWT" \
                      "https://hub.docker.com/v2/repositories/$DOCKERHUB_USER/$REPO/tags/?page_size=100" \
                      | jq -r '.results[].name' \
                      | grep -E '^[0-9]+$' | sort -n)

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
                          -H "Authorization: JWT $JWT" \
                          "https://hub.docker.com/v2/repositories/$DOCKERHUB_USER/$REPO/tags/$TAG/"
                    done

                    echo "Docker Hub cleanup completed"
                    '''
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed — running container remains unchanged"
        }
    }
}
