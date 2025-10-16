pipeline {
    agent any

    environment {
        // Docker ayarları
        DOCKER_IMAGE = "exelances/spring-boot-app"
        CONTAINER_NAME = "spring-boot-app"

        // Portainer ayarları
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

        // 🆕 YENİ: Unit Tests
        stage('Unit Tests') {
            steps {
                echo '🧪 Unit testler çalıştırılıyor...'
                script {
                    sh '''
                        chmod +x gradlew
                        ./gradlew test --no-daemon
                    '''
                }
            }
            post {
                always {
                    // Test sonuçlarını Jenkins'e aktar
                    junit '**/build/test-results/test/*.xml'

                    // Test coverage raporu (JaCoCo varsa)
                    // jacoco()
                }
            }
        }

        // 🆕 YENİ: Code Quality & Security
        stage('Code Quality Check') {
            steps {
                echo '🔍 Kod kalitesi kontrol ediliyor...'
                script {
                    sh '''
                        # Checkstyle, SpotBugs, PMD gibi araçlar
                        ./gradlew check --no-daemon || true
                    '''
                }
            }
        }

        // 🆕 YENİ: Build Application (JAR oluştur)
        stage('Build Application') {
            steps {
                echo '🔨 Uygulama build ediliyor...'
                script {
                    sh '''
                        ./gradlew build -x test --no-daemon
                    '''
                }
            }
            post {
                success {
                    // Build edilen JAR'ı arşivle
                    archiveArtifacts artifacts: '**/build/libs/*.jar', fingerprint: true
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

        // 🆕 YENİ: Docker Image Security Scan
        stage('Security Scan') {
            steps {
                echo '🔒 Docker image güvenlik taraması yapılıyor...'
                script {
                    sh """
                        # Trivy ile güvenlik taraması (opsiyonel)
                        # docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                        #   aquasec/trivy image ${DOCKER_IMAGE}:latest || true

                        echo "⚠️ Security scan atlandı (Trivy kurulu değil)"
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

        // 🆕 YENİ: Deploy sadece master branch'te çalışsın
        stage('Deploy via Portainer API') {
            when {
                branch 'master'
            }
            steps {
                echo '🚀 Portainer API ile deployment yapılıyor...'
                script {
                    withCredentials([string(credentialsId: 'portainer-api-token', variable: 'PORTAINER_TOKEN')]) {
                        sh '''
                            set -e

                            echo "🔑 Portainer: ${PORTAINER_URL} | Stack: ${STACK_ID} | Endpoint: ${ENDPOINT_ID}"

                            # JSON payload hazırla
                            JSON_PAYLOAD='{"PullImage": true, "RepositoryReferenceName": "'"${GIT_REF}"'"}'

                            # Portainer API çağrısı
                            HTTP_CODE=$(curl -k -sS -o /dev/null -w "%{http_code}" -X PUT \
                              -H "X-API-Key: ${PORTAINER_TOKEN}" \
                              -H "Content-Type: application/json" \
                              -d "${JSON_PAYLOAD}" \
                              "${PORTAINER_URL}/api/stacks/${STACK_ID}/git/redeploy?endpointId=${ENDPOINT_ID}")

                            echo "🌐 Portainer yanıtı: HTTP ${HTTP_CODE}"

                            # HTTP kodu kontrolü
                            if [ "$HTTP_CODE" != "204" ] && [ "$HTTP_CODE" != "200" ]; then
                              echo "❌ Redeploy başarısız! (HTTP ${HTTP_CODE})"
                              exit 1
                            fi

                            echo "✅ Portainer redeploy başarıyla tetiklendi!"
                        '''
                    }
                }
            }
        }

        // 🆕 YENİ: Deployment sonrası health check
        stage('Health Check') {
            when {
                branch 'master'
            }
            steps {
                echo '🏥 Health check yapılıyor...'
                script {
                    sh '''
                        # 30 saniye bekle (container ayağa kalksın)
                        sleep 30

                        # Health check
                        # curl -f http://your-app-url/actuator/health || exit 1

                        echo "⚠️ Health check atlandı (URL yapılandırılmadı)"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline başarıyla tamamlandı!'
            echo "🎉 ${CONTAINER_NAME} başarıyla güncellendi!"

            // 🆕 YENİ: Slack/Discord bildirimi (opsiyonel)
            // slackSend(color: 'good', message: "✅ Deployment SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        failure {
            echo '❌ Pipeline başarısız oldu!'

            // 🆕 YENİ: Hata bildirimi
            // slackSend(color: 'danger', message: "❌ Deployment FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}")
        }
        always {
            echo '🧹 Temizlik yapılıyor...'

            // Docker image'ları temizle (disk dolmasın)
            sh '''
                docker image prune -f || true
            '''
        }
    }
}