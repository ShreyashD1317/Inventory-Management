const request = require('supertest');
const app = require('./app');

describe('Inventory Management API - Integration Tests', () => {
  
  describe('Complete Product Lifecycle', () => {
    let createdProductId;
    
    test('Should create, retrieve, update, and delete a product', async () => {
      // 1. Create a new product
      const newProduct = {
        name: 'Integration Test Product',
        category: 'Testing',
        price: 99.99,
        stock: 25,
        sku: 'INT-TEST-001',
        description: 'Product for integration testing'
      };
      
      const createResponse = await request(app)
        .post('/api/products')
        .send(newProduct);
      
      expect(createResponse.status).toBe(201);
      expect(createResponse.body.success).toBe(true);
      expect(createResponse.body.data).toHaveProperty('id');
      
      createdProductId = createResponse.body.data.id;
      
      // 2. Retrieve the created product
      const getResponse = await request(app)
        .get(`/api/products/${createdProductId}`);
      
      expect(getResponse.status).toBe(200);
      expect(getResponse.body.data.name).toBe(newProduct.name);
      expect(getResponse.body.data.sku).toBe(newProduct.sku);
      
      // 3. Update the product
      const updates = {
        name: 'Updated Integration Test Product',
        price: 149.99
      };
      
      const updateResponse = await request(app)
        .put(`/api/products/${createdProductId}`)
        .send(updates);
      
      expect(updateResponse.status).toBe(200);
      expect(updateResponse.body.data.name).toBe(updates.name);
      expect(updateResponse.body.data.price).toBe(updates.price);
      
      // 4. Update stock
      const stockUpdate = await request(app)
        .patch(`/api/products/${createdProductId}/stock`)
        .send({ quantity: 10, operation: 'add' });
      
      expect(stockUpdate.status).toBe(200);
      expect(stockUpdate.body.data.stock).toBe(35);
      
      // 5. Delete the product
      const deleteResponse = await request(app)
        .delete(`/api/products/${createdProductId}`);
      
      expect(deleteResponse.status).toBe(200);
      
      // 6. Verify deletion
      const verifyDelete = await request(app)
        .get(`/api/products/${createdProductId}`);
      
      expect(verifyDelete.status).toBe(404);
    });
  });
  
  describe('Stock Management Workflow', () => {
    test('Should handle inventory operations correctly', async () => {
      // Create a test product
      const product = await request(app)
        .post('/api/products')
        .send({
          name: 'Stock Test Item',
          category: 'Testing',
          price: 29.99,
          stock: 100,
          sku: 'STK-TEST-001'
        });
      
      const productId = product.body.data.id;
      
      // Add stock
      await request(app)
        .patch(`/api/products/${productId}/stock`)
        .send({ quantity: 50, operation: 'add' });
      
      let check = await request(app).get(`/api/products/${productId}`);
      expect(check.body.data.stock).toBe(150);
      
      // Subtract stock
      await request(app)
        .patch(`/api/products/${productId}/stock`)
        .send({ quantity: 30, operation: 'subtract' });
      
      check = await request(app).get(`/api/products/${productId}`);
      expect(check.body.data.stock).toBe(120);
      
      // Set stock
      await request(app)
        .patch(`/api/products/${productId}/stock`)
        .send({ quantity: 75, operation: 'set' });
      
      check = await request(app).get(`/api/products/${productId}`);
      expect(check.body.data.stock).toBe(75);
      
      // Cleanup
      await request(app).delete(`/api/products/${productId}`);
    });
  });
  
  describe('Filtering and Pagination', () => {
    test('Should filter and paginate products correctly', async () => {
      // Get all products
      const allProducts = await request(app).get('/api/products');
      expect(allProducts.status).toBe(200);
      
      // Filter by category
      const electronics = await request(app)
        .get('/api/products?category=Electronics');
      expect(electronics.body.data.every(p => p.category === 'Electronics')).toBe(true);
      
      // Pagination
      const page1 = await request(app)
        .get('/api/products?page=1&limit=2');
      expect(page1.body.data.length).toBeLessThanOrEqual(2);
      expect(page1.body.pagination.currentPage).toBe(1);
      
      // Check stats endpoint
      const stats = await request(app).get('/api/stats');
      expect(stats.status).toBe(200);
      expect(stats.body.data).toHaveProperty('totalProducts');
    });
  });
  
  describe('Error Handling', () => {
    test('Should handle validation errors gracefully', async () => {
      // Missing required fields
      const invalidProduct = {
        name: 'Test'
        // Missing required fields
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(invalidProduct);
      
      expect(response.status).toBe(400);
      expect(response.body.success).toBe(false);
      expect(response.body).toHaveProperty('errors');
    });
    
    test('Should prevent duplicate SKU', async () => {
      const duplicate = {
        name: 'Duplicate Test',
        category: 'Test',
        price: 10,
        stock: 1,
        sku: 'ELEC-LAP-001' // Existing SKU
      };
      
      const response = await request(app)
        .post('/api/products')
        .send(duplicate);
      
      expect(response.status).toBe(409);
    });
  });
});