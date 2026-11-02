
pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        timestamps()

        // Keep only the latest 5 builds
        buildDiscarder(logRotator(
            numToKeepStr: '4'
        ))
    }

    environment {
        REGISTRY = '172.19.62.235:5000'
        IMAGE_NAME = 'jenkins-trial'
        NAMESPACE = 'jenkins-trial'
        DEPLOYMENT = 'jenkins-trial'
        CONTAINER = 'react-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                echo 'Source code checked out successfully.'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                    env.IMAGE_REPO = "${env.REGISTRY}/${env.IMAGE_NAME}"
                }

                sh '''
                    docker build \
                        -t ${IMAGE_REPO}:${IMAGE_TAG} .

                    docker image inspect ${IMAGE_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Push Image to Registry') {
            steps {
                sh '''
                    docker push ${IMAGE_REPO}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy to MicroK8s') {
            steps {
                sh '''
                    microk8s kubectl apply -f k8s/namespace.yaml
                    microk8s kubectl apply -f k8s/service.yaml

                    sed "s|image: .*|image: ${IMAGE_REPO}:${IMAGE_TAG}|" \
                        k8s/deployment.yaml \
                        | microk8s kubectl apply -f -

                    microk8s kubectl rollout status \
                        deployment/${DEPLOYMENT} \
                        -n ${NAMESPACE} \
                        --timeout=180s
                '''
            }
        }

        stage('Promote Production Tags') {
            steps {
                sh '''
                    # Preserve the previous production image.
                    if docker pull ${IMAGE_REPO}:current; then
                        docker tag \
                            ${IMAGE_REPO}:current \
                            ${IMAGE_REPO}:current-1

                        docker push ${IMAGE_REPO}:current-1
                    fi

                    # Promote the successfully deployed image.
                    docker tag \
                        ${IMAGE_REPO}:${IMAGE_TAG} \
                        ${IMAGE_REPO}:current

                    docker push ${IMAGE_REPO}:current
                '''
            }
        }
    }

    post {
        success {
            echo 'React application deployed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
