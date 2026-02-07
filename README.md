# Inventory Management API

A production-ready RESTful API for inventory management with enterprise-grade DevOps practices, comprehensive testing, and automated CI/CD pipeline.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://jenkins.example.com)
[![Coverage](https://img.shields.io/badge/coverage-85%25-green)](https://sonarqube.example.com)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Node Version](https://img.shields.io/badge/node-%3E%3D18.0.0-brightgreen)](https://nodejs.org)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Security](#security)
- [Deployment](#deployment)
- [Configuration](#configuration)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

The Inventory Management API is a modern, scalable REST API built with Node.js and Express.js that provides complete inventory management capabilities. The project demonstrates professional software development practices including automated testing, continuous integration/deployment, security scanning, code quality analysis, and production monitoring.

### Key Capabilities

- Full CRUD operations for product inventory management
- Advanced filtering, pagination, and search functionality
- Real-time stock level management with multiple operations
- Comprehensive validation and error handling
- Production-grade security with rate limiting and input sanitization
- Prometheus metrics for monitoring and observability
- Docker containerization for consistent deployments
- Automated CI/CD pipeline with Jenkins

---

## Features

### Core Functionality

- **Product Management**: Create, read, update, and delete products with full validation
- **Stock Operations**: Add, subtract, or set stock levels with transaction-like operations
- **Advanced Filtering**: Filter by category, price range, stock availability, and more
- **Pagination**: Efficient data retrieval with customizable page size
- **Statistics Dashboard**: Real-time inventory metrics and analytics
- **Health Checks**: Kubernetes-ready liveness and readiness probes

### Technical Features

- **RESTful Architecture**: Follows REST best practices with proper HTTP methods and status codes
- **Input Validation**: Comprehensive validation using express-validator
- **Security Middleware**: Helmet.js, CORS, and rate limiting protection
- **Error Handling**: Centralized error handling with detailed error responses
- **Logging**: Structured logging for all requests and operations
- **Metrics Export**: Prometheus-compatible metrics endpoint
- **Graceful Shutdown**: Proper cleanup on SIGTERM signals
- **Health Monitoring**: Dedicated endpoints for container orchestration

---

## Architecture

### Application Structure

```
inventory-management-api/
├── app.js                          # Main application entry point
├── app.test.js                     # Comprehensive unit tests
├── integration.test.js             # API integration tests
├── package.json                    # Project dependencies and scripts
├── jest.config.js                  # Testing configuration
├── .eslintrc.js                   # Code quality rules
├── Dockerfile                      # Container image definition
├── docker-compose.yml              # Development environment
├── docker-compose.prod.yml         # Production environment
├── Jenkinsfile                     # CI/CD pipeline definition
├── prometheus.yml                  # Monitoring configuration
├── generate-security-report.ps1   # Security analysis script
└── README.md                       # Project documentation
```

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Load Balancer                          │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
    ┌────▼────┐                 ┌────▼────┐
    │  API    │                 │  API    │
    │Instance │                 │Instance │
    └────┬────┘                 └────┬────┘
         │                           │
         └─────────────┬─────────────┘
                       │
              ┌────────▼────────┐
              │   Prometheus    │
              │   (Metrics)     │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │    Grafana      │
              │ (Visualization) │
              └─────────────────┘
```

---

## Technology Stack

### Runtime & Framework
- **Node.js 18+**: JavaScript runtime environment
- **Express.js 4.18**: Web application framework
- **prom-client**: Prometheus metrics library

### Security & Validation
- **Helmet.js**: Security headers middleware
- **express-validator**: Input validation and sanitization
- **express-rate-limit**: API rate limiting
- **CORS**: Cross-origin resource sharing

### Testing & Quality
- **Jest 29**: Testing framework with coverage reporting
- **Supertest**: HTTP assertion library for API testing
- **ESLint**: Code quality and style enforcement
- **Airbnb Style Guide**: JavaScript coding standards

### DevOps & Infrastructure
- **Docker**: Container platform
- **Docker Compose**: Multi-container orchestration
- **Jenkins**: CI/CD automation server
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Metrics visualization and dashboards
- **Trivy**: Container security scanning
- **SonarQube**: Code quality analysis (optional)

---

## Getting Started

### Prerequisites

Ensure you have the following installed:

- **Node.js** 18.0.0 or higher ([Download](https://nodejs.org))
- **npm** 9.0.0 or higher (comes with Node.js)
- **Docker** 20.10 or higher ([Download](https://www.docker.com))
- **Docker Compose** 2.0 or higher
- **Git** for version control

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/inventory-management-api.git
cd inventory-management-api
```

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Run the Application

**Development Mode:**
```bash
npm run dev
```

**Production Mode:**
```bash
npm start
```

The API will be available at `http://localhost:3000`

#### 4. Using Docker (Recommended)

**Development Environment:**
```bash
docker-compose up -d
```

**Production Environment:**
```bash
docker-compose -f docker-compose.prod.yml up -d
```

**View Logs:**
```bash
docker-compose logs -f
```

**Stop Services:**
```bash
docker-compose down
```

### Verify Installation

Check the health endpoint:
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-07T10:30:00.000Z",
  "uptime": 42.123,
  "environment": "production"
}
```

---

## API Documentation

### Base URL
```
http://localhost:3000
```

### Health & Monitoring Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check for container orchestration |
| `/ready` | GET | Readiness probe endpoint |
| `/metrics` | GET | Prometheus metrics endpoint |

### Product Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/products` | GET | Retrieve all products with filtering and pagination |
| `/api/products/:id` | GET | Get a single product by ID |
| `/api/products` | POST | Create a new product |
| `/api/products/:id` | PUT | Update an existing product |
| `/api/products/:id/stock` | PATCH | Update product stock levels |
| `/api/products/:id` | DELETE | Delete a product |
| `/api/stats` | GET | Get inventory statistics |

### Query Parameters (GET /api/products)

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `category` | string | Filter by category | `?category=Electronics` |
| `minPrice` | number | Minimum price filter | `?minPrice=50` |
| `maxPrice` | number | Maximum price filter | `?maxPrice=1000` |
| `inStock` | boolean | Filter in-stock items | `?inStock=true` |
| `page` | number | Page number (default: 1) | `?page=2` |
| `limit` | number | Items per page (default: 10) | `?limit=20` |

### Request/Response Examples

#### Create a Product

**Request:**
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Wireless Keyboard",
    "category": "Electronics",
    "price": 89.99,
    "stock": 75,
    "sku": "ELEC-KEY-004",
    "description": "Bluetooth mechanical keyboard with RGB lighting"
  }'
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 4,
    "name": "Wireless Keyboard",
    "category": "Electronics",
    "price": 89.99,
    "stock": 75,
    "sku": "ELEC-KEY-004",
    "description": "Bluetooth mechanical keyboard with RGB lighting",
    "createdAt": "2026-02-07T10:30:00.000Z"
  },
  "message": "Product created successfully"
}
```

#### Get Products with Filtering

**Request:**
```bash
curl "http://localhost:3000/api/products?category=Electronics&minPrice=50&maxPrice=200&page=1&limit=5"
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Laptop Pro 15",
      "category": "Electronics",
      "price": 1299.99,
      "stock": 45,
      "sku": "ELEC-LAP-001"
    }
  ],
  "pagination": {
    "currentPage": 1,
    "totalPages": 3,
    "totalItems": 12,
    "itemsPerPage": 5
  }
}
```

#### Update Stock

**Request:**
```bash
curl -X PATCH http://localhost:3000/api/products/1/stock \
  -H "Content-Type: application/json" \
  -d '{
    "quantity": 25,
    "operation": "add"
  }'
```

**Stock Operations:**
- `add`: Increase stock by quantity
- `subtract`: Decrease stock by quantity
- `set`: Set stock to exact quantity

#### Get Inventory Statistics

**Request:**
```bash
curl http://localhost:3000/api/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "totalProducts": 150,
    "totalValue": 125340.50,
    "totalStock": 5420,
    "categories": 8,
    "lowStock": 12,
    "outOfStock": 3,
    "categoryBreakdown": {
      "Electronics": 45,
      "Accessories": 67,
      "Furniture": 38
    }
  }
}
```

---

## Testing

### Test Suite Overview

The project includes comprehensive testing with **85%+ code coverage**:

- **Unit Tests**: Test individual functions and endpoints
- **Integration Tests**: Test complete API workflows
- **Coverage Reports**: HTML and JUnit XML formats

### Running Tests

**All Tests with Coverage:**
```bash
npm test
```

**Watch Mode (for development):**
```bash
npm run test:watch
```

**Integration Tests Only:**
```bash
npm run test:integration
```

**View Coverage Report:**
```bash
npm test
# Open coverage/lcov-report/index.html in browser
```

### Test Structure

```javascript
// Unit Tests (app.test.js)
- Health Check Endpoints
- Product CRUD Operations
- Filtering and Pagination
- Input Validation
- Error Handling
- Statistics Calculation

// Integration Tests (integration.test.js)
- Complete Product Lifecycle
- Stock Management Workflow
- Multi-step Operations
- Data Consistency
```

### Coverage Requirements

The project enforces minimum coverage thresholds:
- **Branches**: 70%
- **Functions**: 70%
- **Lines**: 70%
- **Statements**: 70%

---

## CI/CD Pipeline

### Jenkins Pipeline Overview

The project includes a complete 7-stage Jenkins pipeline that automates the entire software delivery process from code commit to production deployment.

### Pipeline Stages

#### Stage 1: Build
- Install npm dependencies
- Create build artifacts
- Build Docker images with multi-stage builds
- Tag images with build number and commit hash

#### Stage 2: Test
- Execute Jest test suite
- Generate JUnit XML reports
- Create HTML coverage reports
- Archive test artifacts
- Enforce coverage thresholds

#### Stage 3: Code Quality Analysis
- Run ESLint static analysis
- Execute SonarQube scan (if configured)
- Check quality gates
- Generate code metrics reports

#### Stage 4: Security Scan
- Perform npm audit for dependency vulnerabilities
- Scan Docker images with Trivy
- Generate comprehensive security reports
- Categorize findings by severity (Critical, High, Medium, Low)

#### Stage 5: Deploy to Staging
- Deploy containers using Docker Compose
- Run automated smoke tests
- Verify health checks
- Test API endpoints

#### Stage 6: Release to Production
- Tag release versions
- Push images to Docker registry
- Deploy to production environment
- Execute health checks
- Verify API functionality

#### Stage 7: Monitoring & Alerting
- Collect Prometheus metrics
- Configure alert rules
- Generate monitoring dashboards
- Set up notification channels

### Setting Up Jenkins

**Prerequisites:**
```bash
- Jenkins 2.400+
- Docker Pipeline Plugin
- HTML Publisher Plugin
- JUnit Plugin
```

**Configuration Steps:**

1. **Create New Pipeline Job:**
   - New Item → Pipeline
   - Name: `inventory-management-api`
   - Pipeline script from SCM

2. **Configure Repository:**
   - Repository URL: `https://github.com/yourusername/inventory-management-api.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`

3. **Configure Credentials (Optional):**
   - Docker Hub credentials: `dockerhub-credentials`
   - Email/Slack webhook for notifications
   - SonarQube token (if using SonarQube)

4. **Run Pipeline:**
   - Click "Build Now"
   - Monitor console output
   - View test reports and coverage

### Pipeline Artifacts

Each build generates:
- Test reports (JUnit XML)
- Coverage reports (HTML)
- Security findings (Markdown)
- Docker images
- Build logs

---

## Monitoring & Observability

### Prometheus Metrics

The API exposes comprehensive metrics at `/metrics`:

**Application Metrics:**
- `http_requests_total`: Total HTTP requests by method, route, and status
- `http_request_duration_seconds`: Request duration histogram
- `api_products_total`: Total number of products in inventory
- `api_stock_operations_total`: Stock operation counter

**Node.js Metrics:**
- `process_cpu_user_seconds_total`: Process CPU usage
- `process_resident_memory_bytes`: Memory consumption
- `nodejs_eventloop_lag_seconds`: Event loop lag
- `nodejs_heap_size_total_bytes`: Heap memory metrics

### Prometheus Configuration

The included `prometheus.yml` configures:
- Scraping the API every 10 seconds
- Retention of metrics for analysis
- Service discovery configuration

**Access Prometheus:**
```
http://localhost:9090
```

**Sample Queries:**
```promql
# Request rate over 5 minutes
rate(http_requests_total[5m])

# Average response time
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])

# Error rate percentage
sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

### Grafana Dashboards

Production deployment includes Grafana for visualization:

**Access Grafana:**
```
http://localhost:3001
Default credentials: admin / admin123
```

**Available Dashboards:**
- API Performance Overview
- Request Rate and Latency
- Error Tracking
- Resource Utilization
- Business Metrics (inventory levels, operations)

---

## Security

### Security Features

#### 1. Application Security
- **Helmet.js**: Sets 11 security-related HTTP headers
- **CORS**: Configurable cross-origin resource sharing
- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Input Validation**: All inputs validated with express-validator
- **Sanitization**: XSS and SQL injection prevention

#### 2. Dependency Security
- **npm audit**: Automated vulnerability scanning
- **Dependency updates**: Regular updates via Dependabot
- **Lock file**: package-lock.json for deterministic builds

#### 3. Container Security
- **Trivy scanning**: Automated image vulnerability detection
- **Non-root user**: Containers run as non-privileged user (node)
- **Multi-stage builds**: Minimal production images
- **No secrets in images**: Environment-based configuration

#### 4. Network Security
- **Internal networks**: Docker network isolation
- **Exposed ports**: Only necessary ports exposed
- **TLS/SSL ready**: HTTPS configuration support

### Security Scanning

**Manual Security Audit:**
```bash
npm run security:check
```

**Docker Image Scan:**
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image inventory-management-api:latest
```

### Security Reports

The Jenkins pipeline generates comprehensive security reports including:
- Vulnerability counts by severity
- Affected packages and versions
- Available fixes and remediation steps
- CVE references and details

---

## Deployment

### Docker Deployment

#### Development Environment

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f app

# Restart services
docker-compose restart

# Stop services
docker-compose down
```

**Services:**
- `app`: Inventory API on port 3000
- `prometheus`: Metrics collection on port 9090

#### Production Environment

```bash
# Deploy production stack
docker-compose -f docker-compose.prod.yml up -d

# View service status
docker-compose -f docker-compose.prod.yml ps

# Scale API instances
docker-compose -f docker-compose.prod.yml up -d --scale inventory-api=3
```

**Production Services:**
- `inventory-api`: API application
- `prometheus`: Monitoring backend
- `grafana`: Visualization dashboard

### Manual Deployment

```bash
# Build production image
docker build -t inventory-management-api:latest .

# Run container
docker run -d \
  --name inventory-api \
  -p 3000:3000 \
  -e NODE_ENV=production \
  inventory-management-api:latest

# Health check
curl http://localhost:3000/health
```

### Kubernetes Deployment (Advanced)

Example Kubernetes manifests:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: inventory-api
  template:
    metadata:
      labels:
        app: inventory-api
    spec:
      containers:
      - name: api
        image: inventory-management-api:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

---

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NODE_ENV` | Environment (development/production) | development | No |
| `PORT` | Server port | 3000 | No |
| `DOCKER_REGISTRY` | Docker registry URL | - | For registry push |
| `EMAIL_RECIPIENTS` | Email notification recipients | - | For email alerts |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | - | For Slack alerts |

### Application Configuration

**Rate Limiting:**
```javascript
// Modify in app.js
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // requests per windowMs
});
```

**CORS Configuration:**
```javascript
// Modify in app.js
app.use(cors({
  origin: 'https://your-frontend.com',
  credentials: true
}));
```

### Docker Configuration

**Build Arguments:**
```bash
docker build \
  --build-arg NODE_VERSION=18 \
  --build-arg APP_PORT=3000 \
  -t inventory-management-api:latest .
```

**Environment File (.env):**
```env
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
```

---

## Code Quality

### ESLint Configuration

The project uses Airbnb JavaScript Style Guide with custom rules:

**Run Linter:**
```bash
npm run lint
```

**Auto-fix Issues:**
```bash
npm run lint:fix
```

**Key Rules:**
- Maximum line length: 120 characters
- No console statements in production
- Consistent code formatting
- Import order enforcement

### Git Hooks (Optional)

Install pre-commit hooks to enforce quality:

```bash
npm install -D husky lint-staged

# Add to package.json
{
  "husky": {
    "hooks": {
      "pre-commit": "lint-staged"
    }
  },
  "lint-staged": {
    "*.js": ["eslint --fix", "git add"]
  }
}
```

---

## Troubleshooting

### Common Issues

**Port Already in Use:**
```bash
# Find process using port 3000
lsof -i :3000

# Kill the process
kill -9 <PID>

# Or change port
PORT=3001 npm start
```

**Docker Build Fails:**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker-compose build --no-cache
```

**Tests Failing:**
```bash
# Clear Jest cache
npx jest --clearCache

# Run tests with verbose output
npm test -- --verbose
```

**Health Check Failing:**
```bash
# Check application logs
docker-compose logs app

# Verify container is running
docker-compose ps

# Test health endpoint manually
curl http://localhost:3000/health
```

### Debugging

**Enable Debug Logs:**
```bash
DEBUG=* npm start
```

**Docker Logs:**
```bash
# Follow logs in real-time
docker-compose logs -f

# Last 100 lines
docker-compose logs --tail=100
```

---

## Performance Considerations

### Optimization Tips

1. **Use Production Mode:**
   ```bash
   NODE_ENV=production npm start
   ```

2. **Enable Clustering:**
   ```javascript
   const cluster = require('cluster');
   const numCPUs = require('os').cpus().length;
   
   if (cluster.isMaster) {
     for (let i = 0; i < numCPUs; i++) {
       cluster.fork();
     }
   } else {
     // Start server
   }
   ```

3. **Add Caching:**
   - Use Redis for frequently accessed data
   - Implement HTTP caching headers
   - Cache Prometheus metrics

4. **Database Connection Pooling:**
   - When adding a database, use connection pooling
   - Monitor connection utilization

### Load Testing

```bash
# Install Apache Bench
brew install ab  # macOS
apt-get install apache2-utils  # Ubuntu

# Run load test
ab -n 10000 -c 100 http://localhost:3000/api/products
```

---

## Future Enhancements

### Planned Features

- [ ] Database integration (PostgreSQL/MongoDB)
- [ ] User authentication and authorization (JWT)
- [ ] Real-time updates with WebSockets
- [ ] Search functionality with Elasticsearch
- [ ] Caching layer with Redis
- [ ] API rate limiting per user
- [ ] Swagger/OpenAPI documentation
- [ ] GraphQL endpoint
- [ ] Multi-tenancy support
- [ ] Audit logging

### Infrastructure Improvements

- [ ] Kubernetes deployment templates
- [ ] Blue-green deployment strategy
- [ ] Canary releases
- [ ] Auto-scaling configuration
- [ ] Backup and disaster recovery
- [ ] Multi-region deployment
- [ ] CDN integration

---

## Contributing

We welcome contributions! Please follow these guidelines:

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Run tests:**
   ```bash
   npm test
   npm run lint
   ```
5. **Commit with meaningful messages:**
   ```bash
   git commit -m "feat: add user authentication"
   ```
6. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```
7. **Open a Pull Request**

February 2026  
**Version:** 1.0.0  
**Status:** Production Ready ✅
