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

        stage('Install Dependencies') {
            steps {
                echo "📦 Installing Python dependencies..."
                sh '''
                    python -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Unit Tests') {
            steps {
                echo "✅ Running unit tests..."
                sh '''
                    . venv/bin/activate
                    pytest tests/unit/ -v --cov=app --cov-report=xml
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Integration Tests') {
            steps {
                echo "🧪 Running integration tests with Docker Compose..."
                sh '''
                    docker-compose -f docker-compose.test.yml up --build --abort-on-container-exit
                    docker-compose -f docker-compose.test.yml down
                '''
            }
        }

        stage('Push to Registry') {
            when {
                branch 'main'
            }
            steps {
                echo "📤 Pushing image to Docker registry..."
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
                        docker push ${DOCKER_IMAGE}
                        docker push ${DOCKER_REGISTRY}/${IMAGE_NAME}:latest
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            when {
                branch 'main'
            }
            steps {
                echo "☸️  Deploying to Kubernetes..."
                sh '''
                    kubectl set image deployment/app app=${DOCKER_IMAGE} -n default
                    kubectl rollout status deployment/app -n default
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo "🩺 Checking app health..."
                sh '''
                    sleep 10
                    kubectl get pods -n default
                    kubectl get svc -n default
                '''
            }
        }
    }

    post {
        always {
            echo "📊 Publishing test results..."
            junit 'test-results/*.xml' || true
            publishHTML([
                reportDir: 'htmlcov',
                reportFiles: 'index.html',
                reportName: 'Code Coverage Report'
            ])
        }

        success {
            echo "✅ Pipeline completed successfully!"
        }

        failure {
            echo "❌ Pipeline failed. Check logs above."
        }

        cleanup {
            echo "🧹 Cleaning up..."
            sh 'docker-compose -f docker-compose.test.yml down || true'
        }
    }
}
