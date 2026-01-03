pipeline {
 agent any
 environment {
   IMAGE_NAME="bluegreen-app"
 }
 stages {
  stage('Checkout') {
   steps {
    git 'https://github.com/krishna-coderz/tomcat-blue-green-nginx-full.git'
   }
  }
  stage('Build WAR') {
   steps { sh 'mvn clean package' }
  }
  stage('Docker Build') {
   steps { sh 'docker build -t bluegreen-app:latest .' }
  }
  stage('Deploy Inactive') {
   steps {
    script {
     def blue = sh(script:'docker ps | grep tomcat-blue || true', returnStatus:true)
     if (blue == 0) {
      sh 'docker rm -f tomcat-green || true'
      sh 'docker run -d --name tomcat-green --network app-net bluegreen-app:latest'
      env.NEW_ENV='green'
     } else {
      sh 'docker rm -f tomcat-blue || true'
      sh 'docker run -d --name tomcat-blue --network app-net bluegreen-app:latest'
      env.NEW_ENV='blue'
     }
    }
   }
  }
  stage('Health Check') {
   steps {
    script {
     def target = env.NEW_ENV == 'green' ? 'tomcat-green' : 'tomcat-blue'
     sh '''
     for i in {1..10}; do
       if curl -s http://''' + "${target}" + ''' :8080/health.jsp | grep OK; then exit 0; fi
       sleep 5
     done
     exit 1
     '''
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
     docker run -d --name nginx --network app-net -p 80:80        -v $(pwd)/nginx/default.conf:/etc/nginx/conf.d/default.conf nginx
     '''
    }
   }
  }
 }
}
