pipeline {
    agent any
    
    tools {
        maven 'MAVEN_3_9_16' 
        jdk 'JDK_26'       
    }
    
    environment {
        REGISTRY_USER = "alessandrabecerra" 
        IMAGE_NAME    = "alessandrabecerra/deisw-retail-store-u202318947"
        TAG           = "${env.BUILD_NUMBER}" 
    }

    stages {
        stage ('Compile Project') {
            steps {
                withMaven(maven : 'MAVEN_3_9_16') {
                    sh 'mvn clean compile'
                }
            }
        }

        stage('Validate Checkstyle') {
            steps {
                withMaven(maven: 'MAVEN_3_9_16') {
                    sh 'mvn checkstyle:check'
                }
            }
        }

        stage('Validate Unit Tests') {
            steps {
                withMaven(maven: 'MAVEN_3_9_16') {
                    sh 'mvn test'
                }
            }
        }

        stage('Validate Test Coverage') {
            steps {
                withMaven(maven: 'MAVEN_3_9_16') {
                    sh 'mvn verify jacoco:report'
                    sh 'mvn jacoco:check'
                }
            }
        }

        stage ('SonarQube Analysis') {
            steps {
                // 1. Enviar el código a analizar a SonarQube
                withSonarQubeEnv('MiSonarServer') {
                    sh 'mvn sonar:sonar -Dsonar.projectKey=learning-center'
                }
                
                // 2. Pausar el pipeline y esperar la respuesta del Webhook de SonarQube
                script {
                    timeout(time: 10, unit: 'MINUTES') { 
                        def qg = waitForQualityGate()
                        
                        // 3. Evaluar el estado del Quality Gate
                        if (qg.status != 'OK') {
                            error "El pipeline se ha detenido porque el código no superó el Quality Gate de SonarQube. Estado: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Construir y Publicar Imagen Docker') {
            steps {
                // Nos autenticamos de forma segura en Docker Hub usando el ID de credenciales de Jenkins
                withCredentials([usernamePassword(credentialsId: 'DOCKER_HUB_CREDENTIALS', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    script {
                        echo "Iniciando sesión en Docker Hub..."
                        sh "echo '${DOCKER_PASS}' | docker login -u '${DOCKER_USER}' --password-stdin"

                        echo "Construyendo y subiendo imagen optimizada AMD64..."
                        // Al usar buildx push, se construye directamente usando las capas Alpine de tu Dockerfile
                        sh "docker buildx build --platform linux/amd64 -t ${REGISTRY_USER}/${IMAGE_NAME}:${TAG} -t ${REGISTRY_USER}/${IMAGE_NAME}:latest --push ."
                    }
                }
            }
        }
    }
}
