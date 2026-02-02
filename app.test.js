const request = require('supertest');
const app = require('./app');

describe('Inventory Management API - Unit Tests', () => {
  
  describe('Health Check Endpoints', () => {
    test('GET /health should return healthy status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('uptime');
    });
    
    test('GET /ready should return ready status', async () => {
      const response = await request(app).get('/ready');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ready');
    });
    
    test('GET /metrics should return Prometheus metrics', async () => {
      const response = await request(app).get('/metrics');
      
      expect(response.status).toBe(200);
      expect(response.text).toContain('http_requests_total');
      expect(response.text).toContain('process_cpu_user_seconds_total');
    });
  });
  
  describe('GET /api/products', () => {
    test('should return all products with pagination', async () => {
      const response = await request(app).get('/api/products');
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.pagination).toHaveProperty('currentPage');
      expect(response.body.pagination).toHaveProperty('totalPages');
    });
    
    test('should filter products by category', async () => {
      const response = await request(app)
        .get('/api/products')
        .query({ category: 'Electronics' });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      
      response.body.data.forEach(product => {
        expect(product.category).toBe('Electronics');
      });
    });
    
    test('should filter products by price range', async () => {
      const response = await request(app)
        .get('/api/products')
        .query({ minPrice: 20, maxPrice: 100 });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      
      response.body.data.forEach(product => {
        expect(product.price).toBeGreaterThanOrEqual(20);
        expect(product.price).toBeLessThanOrEqual(100);
      });
    });
    
    test('should filter products in stock', async () => {
      const response = await request(app)
        .get('/api/products')
        .query({ inStock: 'true' });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      
      response.body.data.forEach(product => {
        expect(product.stock).toBeGreaterThan(0);
      });
    });
    
    test('should handle pagination correctly', async () => {
      const response = await request(app)
        .get('/api/products')
        .query({ page: 1, limit: 2 });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.length).toBeLessThanOrEqual(2);
      expect(response.body.pagination.itemsPerPage).toBe(2);
    });
  });
  
  describe('GET /api/products/:id', () => {
    test('should return a single product by ID', async () => {
      const response = await request(app).get('/api/products/1');
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id', 1);
      expect(response.body.data).toHaveProperty('name');
      expect(response.body.data).toHaveProperty('price');
    });
    
    test('should return 404 for non-existent product', async () => {
      const response = await request(app).get('/api/products/9999');
      
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Product not found');
    });
    
    test('should return 400 for invalid ID format', async () => {
      const response = await request(app).get('/api/products/invalid');
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body).toHaveProperty('errors');
    });
  });
  
  describe('POST /api/products', () => {
    test('should create a new product with valid data', async () => {
      const newProduct = {
        name: 'Test Product',
        category: 'Testing',
        price: 49.99,
        stock: 100,
        sku: 'TEST-PRO-999',
        description: 'A test product'
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(newProduct);
      
      expect(response.status).toBe(201);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('id');
      expect(response.body.data.name).toBe(newProduct.name);
      expect(response.body.data.sku).toBe(newProduct.sku);
    });
    
    test('should return 400 for missing required fields', async () => {
      const invalidProduct = {
        name: 'Test Product'
        // Missing required fields
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(invalidProduct);
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body).toHaveProperty('errors');
    });
    
    test('should return 400 for invalid price', async () => {
      const invalidProduct = {
        name: 'Test Product',
        category: 'Testing',
        price: -10, // Invalid negative price
        stock: 100,
        sku: 'TEST-PRO-998'
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(invalidProduct);
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
    
    test('should return 409 for duplicate SKU', async () => {
      const duplicateProduct = {
        name: 'Another Product',
        category: 'Testing',
        price: 29.99,
        stock: 50,
        sku: 'ELEC-LAP-001' // Existing SKU
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(duplicateProduct);
      
      expect(response.status).toBe(409);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('SKU already exists');
    });
  });
  
  describe('PUT /api/products/:id', () => {
    test('should update an existing product', async () => {
      const updates = {
        name: 'Updated Laptop',
        price: 1399.99
      };
      
      const response = await request(app)
        .put('/api/products/1')
        .send(updates);
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe(updates.name);
      expect(response.body.data.price).toBe(updates.price);
      expect(response.body.data).toHaveProperty('updatedAt');
    });
    
    test('should return 404 for non-existent product', async () => {
      const response = await request(app)
        .put('/api/products/9999')
        .send({ name: 'Test' });
      
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });
  
  describe('PATCH /api/products/:id/stock', () => {
    test('should add stock to a product', async () => {
      const response = await request(app)
        .patch('/api/products/2/stock')
        .send({ quantity: 50, operation: 'add' });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.stock).toBeGreaterThan(150);
    });
    
    test('should subtract stock from a product', async () => {
      const response = await request(app)
        .patch('/api/products/2/stock')
        .send({ quantity: 10, operation: 'subtract' });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
    });
    
    test('should set stock to a specific value', async () => {
      const response = await request(app)
        .patch('/api/products/2/stock')
        .send({ quantity: 100, operation: 'set' });
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.stock).toBe(100);
    });
    
    test('should return 400 for insufficient stock on subtract', async () => {
      const response = await request(app)
        .patch('/api/products/2/stock')
        .send({ quantity: 10000, operation: 'subtract' });
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toContain('Insufficient stock');
    });
    
    test('should return 400 for invalid operation', async () => {
      const response = await request(app)
        .patch('/api/products/2/stock')
        .send({ quantity: 10, operation: 'invalid' });
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
    });
  });
  
  describe('DELETE /api/products/:id', () => {
    test('should delete an existing product', async () => {
      // First create a product to delete
      const newProduct = await request(app)
        .post('/api/products')
        .send({
          name: 'To Delete',
          category: 'Test',
          price: 10.00,
          stock: 1,
          sku: 'DEL-TEST-001'
        });
      
      const productId = newProduct.body.data.id;
      
      const response = await request(app).delete(`/api/products/${productId}`);
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data.id).toBe(productId);
      
      // Verify it's deleted
      const getResponse = await request(app).get(`/api/products/${productId}`);
      expect(getResponse.status).toBe(404);
    });
    
    test('should return 404 for non-existent product', async () => {
      const response = await request(app).delete('/api/products/9999');
      
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
    });
  });
  
  describe('GET /api/stats', () => {
    test('should return inventory statistics', async () => {
      const response = await request(app).get('/api/stats');
      
      expect(response.status).toBe(200);
      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('totalProducts');
      expect(response.body.data).toHaveProperty('totalValue');
      expect(response.body.data).toHaveProperty('totalStock');
      expect(response.body.data).toHaveProperty('categories');
      expect(response.body.data).toHaveProperty('lowStock');
      expect(response.body.data).toHaveProperty('outOfStock');
      expect(response.body.data).toHaveProperty('categoryBreakdown');
      
      expect(typeof response.body.data.totalProducts).toBe('number');
      expect(typeof response.body.data.totalValue).toBe('number');
    });
  });
  
  describe('Error Handling', () => {
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/api/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body.success).toBe(false);
      expect(response.body.error).toBe('Route not found');
    });
  });
});