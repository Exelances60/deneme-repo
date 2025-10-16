pipeline {
    agent any

    tools {
        jdk 'JDK_21' // JDK 21 kullanılıyor
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
        stage('Cleanup Workspace') {
            steps {
                echo '🧹 Workspace temizleniyor...'
                cleanWs()
            }
        }

        stage('Checkout Code') {
            steps {
                echo '📥 Kod checkout ediliyor...'
                checkout scm
            }
        }

        stage('Deep Clean') {
            steps {
                echo '🗑️ Derin temizlik yapılıyor...'
                script {
                    sh '''
                        # Tüm Gradle cache'i temizle
                        rm -rf /root/.gradle/
                        rm -rf .gradle/
                        rm -rf build/

                        # Gradle wrapper'ı yeniden indirin
                        chmod +x gradlew

                        echo "✅ Derin temizlik tamamlandı!"
                    '''
                }
            }
        }

        stage('Verify Environment') {
            steps {
                echo '🔍 Ortam kontrol ediliyor...'
                script {
                    sh '''
                        echo "=== Java Version ==="
                        java -version 2>&1
                        echo ""
                        echo "=== Gradle Version ==="
                        ./gradlew --version || echo "Gradle henüz hazır değil"
                    '''
                }
            }
        }

        stage('Build Application') {
            steps {
                echo '🔨 Uygulama build ediliyor...'
                script {
                    sh '''
                        # Gradle daemon'sız ve test'siz build
                        ./gradlew clean build -x test --no-daemon --refresh-dependencies --info
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Docker image oluşturuluyor...'
                script {
                    sh """
                        docker build -t ${DOCKER_IMAGE}:latest .
                        docker tag ${DOCKER_IMAGE}:latest ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    """
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '📤 Docker Hub\'a push ediliyor...'
                script {
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
        }

        stage('Deploy via Portainer API') {
            when { branch 'master' }
            steps {
                echo '🚀 Portainer API ile deployment yapılıyor...'
                script {
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
    }

    post {
        success {
            echo '✅ Pipeline başarıyla tamamlandı!'
        }
        failure {
            echo '❌ Pipeline başarısız oldu!'
        }
        always {
            echo '🧹 Temizlik yapılıyor...'
            sh 'docker image prune -f || true'
        }
    }
}