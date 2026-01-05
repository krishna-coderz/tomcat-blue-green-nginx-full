pipeline {
    agent any

    environment {
        IMAGE_NAME = "bluegreen-app"
        BLUE_PORT  = "8081"
        GREEN_PORT = "8082"
        STATE_FILE = "active_env.txt"
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/krishna-coderz/tomcat-blue-green-nginx-full.git'
            }
        }

        stage('Detect Active Environment') {
            steps {
                script {
                    env.ACTIVE_ENV = readFile(STATE_FILE).trim()
                    env.NEW_ENV = (env.ACTIVE_ENV == "blue") ? "green" : "blue"

                    env.NEW_PORT = (env.NEW_ENV == "blue") ? BLUE_PORT : GREEN_PORT

                    echo "Active: ${env.ACTIVE_ENV}"
                    echo "Deploying to: ${env.NEW_ENV}"
                }
            }
        }

        stage('Build WAR') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:latest .'
            }
        }

        stage('Deploy to Standby') {
            steps {
                script {
                    sh "docker rm -f tomcat-${env.NEW_ENV} || true"

                    sh """
                    docker run -d \
                      --name tomcat-${env.NEW_ENV} \
                      --network app-net \
                      -p ${env.NEW_PORT}:8080 \
                      -e DEPLOY_ENV=${env.NEW_ENV} \
                      ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                echo "Checking health on ${env.NEW_ENV}..."

                until curl -s http://192.168.1.20:${env.NEW_PORT}/health.jsp | grep OK; do
                    echo "Waiting for app..."
                    sleep 10
                done
                """
            }
        }

        stage('Switch Nginx') {
            steps {
                script {
                    sh """
                    sed -i 's/tomcat-${env.ACTIVE_ENV}/tomcat-${env.NEW_ENV}/' nginx/default.conf
                    docker rm -f nginx || true

                    docker run -d --name nginx \
                      --network app-net \
                      -p 80:80 \
                      -v \$(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf \
                      nginx
                    """
                }
            }
        }

        stage('Update Active State') {
            steps {
                writeFile file: STATE_FILE, text: env.NEW_ENV
                echo "Now active: ${env.NEW_ENV}"
            }
        }
    }

    post {
        success {
            echo "✅ ZERO-DOWNTIME DEPLOYMENT COMPLETE"
        }
    }
}
