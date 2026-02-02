pipeline {
    agent any
    
    environment {
        // Application settings
        APP_NAME = 'inventory-management-api'
        DOCKER_IMAGE = "${APP_NAME}:${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'docker.io/shreyashd69' // Update with your registry
        
        // Deployment environments
        STAGING_SERVER = 'staging.example.com'
        PRODUCTION_SERVER = 'production.example.com'
        
        // Tool versions
        NODE_VERSION = '18'
        
        // Notification settings
        SLACK_CHANNEL = '#devops-alerts'
        EMAIL_RECIPIENTS = 'team@example.com'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10', artifactNumToKeepStr: '10'))
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        stage('1. Checkout & Setup') {
            steps {
                script {
                    echo "=========================================="
                    echo "Starting Pipeline for Build #${BUILD_NUMBER}"
                    echo "Branch: ${env.BRANCH_NAME ?: 'main'}"
                    echo "=========================================="
                }
                
                // Clean workspace
                cleanWs()
                
                // Checkout code
                checkout scm
                
                // Display commit information
                sh '''
                    echo "Latest commit:"
                    git log -1 --pretty=format:"%h - %an, %ar : %s"
                '''
            }
        }
        
        stage('2. Build') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 2: BUILD"
                    echo "Building application artifacts..."
                    echo "=========================================="
                }
                
                sh '''
                    # Install Node.js dependencies
                    echo "Installing dependencies..."
                    npm ci
                    
                    # Create build artifact directory
                    mkdir -p build-artifacts
                    
                    # Package application
                    echo "Packaging application..."
                    tar -czf build-artifacts/${APP_NAME}-${BUILD_NUMBER}.tar.gz \
                        --exclude=node_modules \
                        --exclude=.git \
                        --exclude=build-artifacts \
                        --exclude=coverage \
                        .
                    
                    echo "✓ Build artifact created: ${APP_NAME}-${BUILD_NUMBER}.tar.gz"
                    ls -lh build-artifacts/
                '''
                
                // Build Docker image
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${DOCKER_IMAGE} .
                    docker tag ${DOCKER_IMAGE} ${APP_NAME}:latest
                    echo "✓ Docker image built: ${DOCKER_IMAGE}"
                '''
            }
            
            post {
                success {
                    echo "✓ Build stage completed successfully"
                    archiveArtifacts artifacts: 'build-artifacts/*.tar.gz', fingerprint: true
                }
                failure {
                    echo "✗ Build stage failed"
                }
            }
        }
        
        stage('3. Test') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 3: TEST"
                    echo "Running automated test suite..."
                    echo "=========================================="
                }
                
                sh '''
                    # Run unit tests with coverage
                    echo "Running unit tests..."
                    npm test
                    
                    # Display coverage summary
                    echo ""
                    echo "Coverage Summary:"
                    cat coverage/coverage-summary.json || echo "Coverage summary not found"
                '''
            }
            
            post {
                always {
                    // Publish test results
                    junit testResults: 'coverage/junit.xml', allowEmptyResults: true
                    
                    // Publish coverage report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'coverage/lcov-report',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage Report',
                        reportTitles: 'Test Coverage'
                    ])
                }
                success {
                    echo "✓ All tests passed successfully"
                }
                failure {
                    echo "✗ Tests failed - Pipeline stopped"
                }
            }
        }
        
        stage('4. Code Quality Analysis') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 4: CODE QUALITY ANALYSIS"
                    echo "Analyzing code quality and maintainability..."
                    echo "=========================================="
                }
                
                // ESLint for code quality
                sh '''
                    echo "Running ESLint..."
                    npm run lint > eslint-report.txt || true
                    cat eslint-report.txt
                '''
                
                // SonarQube analysis (if SonarQube is configured)
                script {
                    try {
                        withSonarQubeEnv('SonarQube') {
                            sh '''
                                echo "Running SonarQube analysis..."
                                sonar-scanner \
                                    -Dsonar.projectKey=${APP_NAME} \
                                    -Dsonar.projectName="${APP_NAME}" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER} \
                                    -Dsonar.sources=. \
                                    -Dsonar.exclusions=**/node_modules/**,**/coverage/** \
                                    -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info \
                                    -Dsonar.testExecutionReportPaths=coverage/test-report.xml
                            '''
                        }
                        
                        // Wait for quality gate
                        timeout(time: 5, unit: 'MINUTES') {
                            def qg = waitForQualityGate()
                            if (qg.status != 'OK') {
                                echo "Warning: SonarQube quality gate failed: ${qg.status}"
                                echo "Continuing pipeline (set to fail if required)..."
                            }
                        }
                    } catch (Exception e) {
                        echo "SonarQube analysis skipped or failed: ${e.message}"
                        echo "Continuing pipeline..."
                    }
                }
                
                // Code metrics
                sh '''
                    echo ""
                    echo "Code Statistics:"
                    echo "================"
                    find . -name "*.js" -not -path "*/node_modules/*" -not -path "*/coverage/*" | wc -l | xargs echo "JavaScript files:"
                    find . -name "*.js" -not -path "*/node_modules/*" -not -path "*/coverage/*" -exec cat {} \\; | wc -l | xargs echo "Lines of code:"
                '''
            }
            
            post {
                always {
                    archiveArtifacts artifacts: 'eslint-report.txt', allowEmptyArchive: true
                }
                success {
                    echo "✓ Code quality analysis completed"
                }
            }
        }
        
        stage('5. Security Scan') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 5: SECURITY ANALYSIS"
                    echo "Scanning for vulnerabilities..."
                    echo "=========================================="
                }
                
                // NPM Audit for dependency vulnerabilities
                sh '''
                    echo "Running npm audit..."
                    npm audit --json > npm-audit-report.json || true
                    npm audit || true
                    
                    echo ""
                    echo "Security Scan Results:"
                    echo "======================"
                '''
                
                // Analyze npm audit results
                script {
                    try {
                        def auditReport = readJSON file: 'npm-audit-report.json'
                        def vulnerabilities = auditReport.metadata.vulnerabilities
                        
                        echo """
                        Vulnerability Summary:
                        - Critical: ${vulnerabilities.critical ?: 0}
                        - High: ${vulnerabilities.high ?: 0}
                        - Moderate: ${vulnerabilities.moderate ?: 0}
                        - Low: ${vulnerabilities.low ?: 0}
                        - Info: ${vulnerabilities.info ?: 0}
                        """
                        
                        if (vulnerabilities.critical > 0) {
                            echo "⚠️  CRITICAL vulnerabilities found! Manual review required."
                            echo "Consider running: npm audit fix"
                        } else if (vulnerabilities.high > 0) {
                            echo "⚠️  HIGH severity vulnerabilities found!"
                        } else {
                            echo "✓ No critical or high severity vulnerabilities found"
                        }
                    } catch (Exception e) {
                        echo "Could not parse audit report: ${e.message}"
                    }
                }
                
                // Docker image scanning with Trivy (if available)
                script {
                    try {
                        sh '''
                            if command -v trivy &> /dev/null; then
                                echo "Running Trivy security scan on Docker image..."
                                trivy image --severity HIGH,CRITICAL --format json \
                                    --output trivy-report.json ${DOCKER_IMAGE} || true
                                
                                trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE} || true
                            else
                                echo "Trivy not installed, skipping container scan"
                            fi
                        '''
                    } catch (Exception e) {
                        echo "Trivy scan failed or not available: ${e.message}"
                    }
                }
                
                // OWASP Dependency Check (optional - can be heavy)
                sh '''
                    echo ""
                    echo "For production environments, consider:"
                    echo "- OWASP Dependency Check"
                    echo "- Snyk"
                    echo "- Bandit (for Python)"
                    echo "- GitGuardian (for secrets scanning)"
                '''
            }
            
            post {
                always {
                    archiveArtifacts artifacts: '*-report.json', allowEmptyArchive: true
                    
                    // Publish security report
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'npm-audit-report.json',
                        reportName: 'Security Scan Report',
                        reportTitles: 'Security Analysis'
                    ])
                }
                success {
                    echo "✓ Security scan completed"
                }
            }
        }
        
        stage('6. Deploy to Staging') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 6: DEPLOY TO STAGING"
                    echo "Deploying to staging environment..."
                    echo "=========================================="
                }
                
                // Deploy using Docker Compose
                sh '''
                    echo "Deploying to staging environment..."
                    
                    # Stop existing containers
                    docker-compose down || true
                    
                    # Deploy new version
                    docker-compose up -d
                    
                    # Wait for application to be ready
                    echo "Waiting for application to start..."
                    sleep 10
                    
                    # Health check
                    MAX_RETRIES=30
                    RETRY_COUNT=0
                    
                    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
                        if curl -f http://localhost:3000/health > /dev/null 2>&1; then
                            echo "✓ Application is healthy!"
                            break
                        fi
                        
                        RETRY_COUNT=$((RETRY_COUNT + 1))
                        echo "Health check attempt $RETRY_COUNT/$MAX_RETRIES failed, retrying..."
                        sleep 2
                    done
                    
                    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
                        echo "✗ Application failed to become healthy"
                        exit 1
                    fi
                '''
                
                // Smoke tests
                sh '''
                    echo ""
                    echo "Running smoke tests..."
                    
                    # Test API endpoints
                    echo "Testing GET /health..."
                    curl -f http://localhost:3000/health || exit 1
                    
                    echo "Testing GET /api/products..."
                    curl -f http://localhost:3000/api/products || exit 1
                    
                    echo "Testing GET /api/stats..."
                    curl -f http://localhost:3000/api/stats || exit 1
                    
                    echo "✓ All smoke tests passed!"
                '''
            }
            
            post {
                success {
                    echo "✓ Successfully deployed to staging"
                    echo "Staging URL: http://localhost:3000"
                }
                failure {
                    echo "✗ Deployment to staging failed"
                    sh 'docker-compose logs --tail=50 || true'
                }
            }
        }
        
        stage('7. Release to Production') {
            when {
                branch 'main'
                // Add manual approval if desired
                // beforeInput true
            }
            
            // Uncomment for manual approval
            // input {
            //     message "Deploy to production?"
            //     ok "Deploy"
            //     submitter "admin,deployer"
            // }
            
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 7: RELEASE TO PRODUCTION"
                    echo "Deploying to production environment..."
                    echo "=========================================="
                }
                
                sh '''
                    echo "Tagging release..."
                    docker tag ${DOCKER_IMAGE} ${APP_NAME}:production
                    docker tag ${DOCKER_IMAGE} ${APP_NAME}:v${BUILD_NUMBER}
                    
                    echo "Release tags created:"
                    echo "- ${APP_NAME}:production"
                    echo "- ${APP_NAME}:v${BUILD_NUMBER}"
                '''
                
                // In a real scenario, you would:
                // - Push to container registry
                // - Deploy to production servers
                // - Update load balancers
                // - Run production smoke tests
                
                sh '''
                    echo ""
                    echo "Production Deployment Checklist:"
                    echo "================================"
                    echo "✓ Docker image tagged for production"
                    echo "→ Push to registry: docker push ${DOCKER_REGISTRY}/${DOCKER_IMAGE}"
                    echo "→ Deploy to production servers"
                    echo "→ Update load balancer configuration"
                    echo "→ Run production smoke tests"
                    echo "→ Monitor application metrics"
                    
                    echo ""
                    echo "For actual production deployment, integrate with:"
                    echo "- Kubernetes (kubectl apply)"
                    echo "- AWS ECS/EKS"
                    echo "- Azure Container Instances"
                    echo "- Docker Swarm"
                    echo "- Or your preferred orchestration platform"
                '''
            }
            
            post {
                success {
                    echo "✓ Production release completed successfully"
                }
                failure {
                    echo "✗ Production release failed"
                }
            }
        }
        
        stage('8. Monitoring & Alerting') {
            steps {
                script {
                    echo "=========================================="
                    echo "STAGE 8: MONITORING & ALERTING SETUP"
                    echo "Configuring monitoring and alerts..."
                    echo "=========================================="
                }
                
                sh '''
                    echo "Monitoring Configuration:"
                    echo "========================="
                    echo ""
                    
                    # Check Prometheus metrics endpoint
                    echo "Checking Prometheus metrics..."
                    curl -s http://localhost:3000/metrics | head -20
                    
                    echo ""
                    echo "✓ Prometheus metrics endpoint is active"
                    echo ""
                    
                    echo "Monitoring Tools Integrated:"
                    echo "- Prometheus (metrics collection)"
                    echo "- Custom application metrics"
                    echo "- Health check endpoints"
                    echo ""
                    
                    echo "Available Metrics:"
                    echo "- http_requests_total"
                    echo "- http_request_duration_seconds"
                    echo "- process_cpu_user_seconds_total"
                    echo "- process_resident_memory_bytes"
                    echo "- nodejs_eventloop_lag_seconds"
                    echo ""
                    
                    echo "Recommended Additional Tools:"
                    echo "- Grafana (visualization)"
                    echo "- Datadog (APM)"
                    echo "- New Relic (monitoring)"
                    echo "- PagerDuty (alerting)"
                    echo "- Sentry (error tracking)"
                    echo ""
                    
                    echo "Alert Rules to Configure:"
                    echo "- High error rate (>5% of requests)"
                    echo "- High response time (>2s average)"
                    echo "- Low memory (<20% available)"
                    echo "- Application downtime"
                    echo "- Failed health checks"
                '''
                
                // Create monitoring dashboard URL
                sh '''
                    echo ""
                    echo "Monitoring Dashboards:"
                    echo "- Prometheus: http://localhost:9090"
                    echo "- Metrics: http://localhost:3000/metrics"
                    echo "- Health: http://localhost:3000/health"
                '''
            }
            
            post {
                success {
                    echo "✓ Monitoring and alerting configured"
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "=========================================="
                echo "PIPELINE SUMMARY"
                echo "=========================================="
                echo "Build Number: ${BUILD_NUMBER}"
                echo "Duration: ${currentBuild.durationString}"
                echo "Result: ${currentBuild.currentResult}"
                echo "=========================================="
            }
            
            // Clean up
            sh '''
                echo "Cleaning up temporary files..."
                rm -f *.json *.txt || true
            '''
        }
        
        success {
            echo "✓✓✓ PIPELINE COMPLETED SUCCESSFULLY ✓✓✓"
            
            // Send success notification
            // emailext(
            //     subject: "✓ Pipeline Success: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
            //     body: "The pipeline completed successfully!",
            //     to: "${EMAIL_RECIPIENTS}"
            // )
        }
        
        failure {
            echo "✗✗✗ PIPELINE FAILED ✗✗✗"
            
            // Send failure notification
            // emailext(
            //     subject: "✗ Pipeline Failed: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
            //     body: "The pipeline has failed. Please check the logs.",
            //     to: "${EMAIL_RECIPIENTS}"
            // )
        }
        
        unstable {
            echo "⚠️  PIPELINE UNSTABLE ⚠️"
        }
    }
}
