pipeline {
    agent any

    environment {
        IMAGE_NAME = "bluegreen-app"
        BLUE_PORT  = "8081"
        GREEN_PORT = "8082"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/krishna-coderz/tomcat-blue-green-nginx-full.git'
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t bluegreen-app:latest .'
            }
        }

        stage('Deploy Inactive') {
            steps {
                script {
                    def blueRunning = sh(
                        script: "docker ps --format '{{.Names}}' | grep -w tomcat-blue || true",
                        returnStatus: true
                    )

                    if (blueRunning == 0) {
                        // BLUE is active → deploy GREEN
                        sh 'docker rm -f tomcat-green || true'
                        sh """
                        docker run -d \
                          --name tomcat-green \
                          --network app-net \
                          -p ${GREEN_PORT}:8080 \
                          -e DEPLOY_ENV=green \
                          bluegreen-app:latest
                        """
                        env.NEW_ENV = 'green'
                        env.HEALTH_PORT = GREEN_PORT
                    } else {
                        // GREEN is active → deploy BLUE
                        sh 'docker rm -f tomcat-blue || true'
                        sh """
                        docker run -d \
                          --name tomcat-blue \
                          --network app-net \
                          -p ${BLUE_PORT}:8080 \
                          -e DEPLOY_ENV=blue \
                          bluegreen-app:latest
                        """
                        env.NEW_ENV = 'blue'
                        env.HEALTH_PORT = BLUE_PORT
                    }
                }
            }
        }

        stage('Health Check (Wait Until OK)') {
            steps {
                script {
                    sh """
                    echo "Waiting for application to become healthy on 192.168.1.20:${env.HEALTH_PORT}"

                    while true; do
                        RESPONSE=\$(curl -s http://192.168.1.20:${env.HEALTH_PORT}/health.jsp || true)
                        echo "Health response: [\$RESPONSE]"

                        if echo "\$RESPONSE" | grep -q "OK"; then
                            echo "✅ Health check OK — proceeding"
                            break
                        fi

                        echo "⏳ App not ready yet, retrying in 15 seconds..."
                        sleep 15
                    done
                    """
                }
            }
        }

        stage('Switch Nginx') {
            steps {
                script {
                    if (env.NEW_ENV == 'green') {
                        sh "sed -i 's/tomcat-blue/tomcat-green/' nginx/default.conf"
                    } else {
                        sh "sed -i 's/tomcat-green/tomcat-blue/' nginx/default.conf"
                    }

                    sh '''
                    docker rm -f nginx || true
                    docker run -d --name nginx \
                      --network app-net \
                      -p 80:80 \
                      -v $(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf \
                      nginx
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment successful. Active environment: ${env.NEW_ENV.toUpperCase()}"
        }
    }
}
