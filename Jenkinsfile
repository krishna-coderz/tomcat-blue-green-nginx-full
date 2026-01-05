pipeline {
    agent any

    parameters {
        choice(
            name: 'TARGET_ENV',
            choices: ['blue', 'green'],
            description: 'Select environment to deploy latest app'
        )
    }

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

        stage('Prepare Environment') {
            steps {
                script {
                    env.DEPLOY_ENV = params.TARGET_ENV
                    env.DEPLOY_PORT = (env.DEPLOY_ENV == 'blue') ? BLUE_PORT : GREEN_PORT
                    env.OLD_ENV = (env.DEPLOY_ENV == 'blue') ? 'green' : 'blue'

                    echo "Deploying to: ${env.DEPLOY_ENV}"
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

        stage('Deploy Selected Environment') {
            steps {
                script {
                    sh "docker rm -f tomcat-${env.DEPLOY_ENV} || true"

                    sh """
                    docker run -d \
                      --name tomcat-${env.DEPLOY_ENV} \
                      --network app-net \
                      -p ${env.DEPLOY_PORT}:8080 \
                      -e DEPLOY_ENV=${env.DEPLOY_ENV} \
                      ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                until curl -s http://192.168.1.20:${env.DEPLOY_PORT}/health.jsp | grep OK; do
                    echo "Waiting for ${env.DEPLOY_ENV}..."
                    sleep 10
                done
                """
            }
        }

        stage('Switch Nginx') {
            steps {
                sh """
                sed -i 's/tomcat-${env.OLD_ENV}/tomcat-${env.DEPLOY_ENV}/' nginx/default.conf

                docker rm -f nginx || true
                docker run -d --name nginx \
                  --network app-net \
                  -p 80:80 \
                  -v \$(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf \
                  nginx
                """
            }
        }

        stage('Update Active State') {
            steps {
                writeFile file: STATE_FILE, text: env.DEPLOY_ENV
                echo "Active environment is now ${env.DEPLOY_ENV}"
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed to ${params.TARGET_ENV.toUpperCase()}"
        }
    }
}
