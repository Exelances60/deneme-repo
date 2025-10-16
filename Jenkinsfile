pipeline {
    agent any

    tools {
        jdk 'JAVA_17'
    }

    environment {
        DOCKER_IMAGE = "exelances/spring-boot-app"
        CONTAINER_NAME = "spring-boot-app"
        PORTAINER_URL = "https://72.61.156.194:9443"
        STACK_ID = "1"
        ENDPOINT_ID = "3"
        GIT_REF = "refs/heads/master"
    }

    stages {
        stage('Verify Java') {
            steps {
                echo '☕ Java versiyonu kontrol ediliyor...'
                sh '''
                    java -version
                    echo "JAVA_HOME: $JAVA_HOME"
                '''
            }
        }

        stage('Checkout Code') {
            steps {
                echo '📥 Kod checkout ediliyor...'
                checkout scm
            }
        }

        stage('Build Application') {
            steps {
                echo '🔨 Uygulama build ediliyor...'
                sh './gradlew clean build -x test --no-daemon'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Docker image oluşturuluyor...'
                sh """
                    docker build -t ${DOCKER_IMAGE}:latest .
                    docker tag ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:${BUILD_NUMBER}
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '📤 Docker Hub\'a push ediliyor...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker logout
                    """
                }
            }
        }

        stage('Deploy via Portainer API') {
            steps {
                echo '🚀 Portainer API ile deployment yapılıyor...'
                withCredentials([string(credentialsId: 'portainer-api-token', variable: 'PORTAINER_TOKEN')]) {
                    sh '''
                        JSON_PAYLOAD='{"PullImage": true, "RepositoryReferenceName": "'"${GIT_REF}"'"}'

                        HTTP_CODE=$(curl -k -sS -o /dev/null -w "%{http_code}" -X PUT \
                          -H "X-API-Key: ${PORTAINER_TOKEN}" \
                          -H "Content-Type: application/json" \
                          -d "${JSON_PAYLOAD}" \
                          "${PORTAINER_URL}/api/stacks/${STACK_ID}/git/redeploy?endpointId=${ENDPOINT_ID}")

                        if [ "$HTTP_CODE" != "204" ] && [ "$HTTP_CODE" != "200" ]; then
                          echo "❌ Deploy failed: HTTP ${HTTP_CODE}"
                          exit 1
                        fi

                        echo "✅ Deploy success!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline başarıyla tamamlandı!'
            echo "🎉 ${CONTAINER_NAME} başarıyla güncellendi!"
        }
        failure {
            echo '❌ Pipeline başarısız oldu!'
        }
    }
}