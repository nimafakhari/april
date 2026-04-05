pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = "docker.io"
        IMAGE_NAME = "new-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code..."
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                script {
                    if (isUnix()) {
                        sh '''
                            docker build -t ${DOCKER_IMAGE} .
                            docker tag ${DOCKER_IMAGE} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                        '''
                    } else {
                        bat '''
                            docker build -t %DOCKER_IMAGE% .
                            docker tag %DOCKER_IMAGE% %DOCKER_REGISTRY%/%IMAGE_NAME%:latest
                        '''
                    }
                }
            }
        }

        stage('Push to Registry') {
            when {
                branch 'main'
            }
            steps {
                echo "📤 Pushing image to Docker registry..."
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    script {
                        if (isUnix()) {
                            sh '''
                                echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                                docker push ${DOCKER_IMAGE}
                                docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                                docker logout
                            '''
                        } else {
                            bat '''
                                echo %DOCKER_PASSWORD% | docker login -u %DOCKER_USERNAME% --password-stdin
                                docker push %DOCKER_IMAGE%
                                docker push %DOCKER_REGISTRY%/%IMAGE_NAME%:latest
                                docker logout
                            '''
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo "☸️  Deploying to Kubernetes..."
                script {
                    if (isUnix()) {
                        sh '''
                            kubectl set image deployment/app app=${DOCKER_IMAGE} -n default
                            kubectl rollout status deployment/app -n default
                        '''
                    } else {
                        bat '''
                            kubectl set image deployment/app app=%DOCKER_IMAGE% -n default
                            kubectl rollout status deployment/app -n default
                        '''
                    }
                }
            }
        }

        stage('Health Check') {
            steps {
                echo "🩺 Checking app health..."
                script {
                    if (isUnix()) {
                        sh '''
                            sleep 10
                            kubectl get pods -n default
                            kubectl get svc -n default
                        '''
                    } else {
                        bat '''
                            ping localhost -n 11 > nul
                            kubectl get pods -n default
                            kubectl get svc -n default
                        '''
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully!"
        }

        failure {
            echo "❌ Pipeline failed. Check logs above."
        }

        cleanup {
            echo "🧹 Cleaning up..."
            script {
                if (isUnix()) {
                    sh 'if [ -f docker-compose.test.yml ]; then docker-compose -f docker-compose.test.yml down; fi || true'
                } else {
                    bat '''
                        if exist docker-compose.test.yml (
                            docker-compose -f docker-compose.test.yml down
                        )
                    '''
                }
            }
        }
    }
}
