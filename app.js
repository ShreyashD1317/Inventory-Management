const express = require('express');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const cors = require('cors');
const { body, validationResult, param } = require('express-validator');
const prometheus = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// Prometheus metrics setup
const register = new prometheus.Registry();
prometheus.collectDefaultMetrics({ register });

const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

const httpRequestTotal = new prometheus.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register]
});

// Security middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Request logging and metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
    httpRequestTotal.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
    
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path} - ${res.statusCode} - ${duration}s`);
  });
  
  next();
});

// In-memory database (simulating database for demo)
let products = [
  {
    id: 1,
    name: 'Laptop Pro 15',
    category: 'Electronics',
    price: 1299.99,
    stock: 45,
    sku: 'ELEC-LAP-001',
    description: 'High-performance laptop with 16GB RAM',
    createdAt: new Date().toISOString()
  },
  {
    id: 2,
    name: 'Wireless Mouse',
    category: 'Accessories',
    price: 29.99,
    stock: 150,
    sku: 'ACC-MOU-002',
    description: 'Ergonomic wireless mouse with USB receiver',
    createdAt: new Date().toISOString()
  },
  {
    id: 3,
    name: 'USB-C Cable',
    category: 'Accessories',
    price: 12.99,
    stock: 200,
    sku: 'ACC-CAB-003',
    description: '2-meter USB-C charging cable',
    createdAt: new Date().toISOString()
  }
];

let nextId = 4;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Readiness check endpoint
app.get('/ready', (req, res) => {
  // Check if app is ready to serve traffic
  if (products.length >= 0) {
    res.status(200).json({ status: 'ready' });
  } else {
    res.status(503).json({ status: 'not ready' });
  }
});

// Metrics endpoint for Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// API Routes

// GET all products with pagination and filtering
app.get('/api/products', (req, res) => {
  try {
    const { category, minPrice, maxPrice, inStock, page = 1, limit = 10 } = req.query;
    
    let filteredProducts = [...products];
    
    // Apply filters
    if (category) {
      filteredProducts = filteredProducts.filter(p => 
        p.category.toLowerCase() === category.toLowerCase()
      );
    }
    
    if (minPrice) {
      filteredProducts = filteredProducts.filter(p => p.price >= parseFloat(minPrice));
    }
    
    if (maxPrice) {
      filteredProducts = filteredProducts.filter(p => p.price <= parseFloat(maxPrice));
    }
    
    if (inStock === 'true') {
      filteredProducts = filteredProducts.filter(p => p.stock > 0);
    }
    
    // Pagination
    const startIndex = (parseInt(page) - 1) * parseInt(limit);
    const endIndex = startIndex + parseInt(limit);
    const paginatedProducts = filteredProducts.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedProducts,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(filteredProducts.length / parseInt(limit)),
        totalItems: filteredProducts.length,
        itemsPerPage: parseInt(limit)
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// GET single product by ID
app.get('/api/products/:id', [
  param('id').isInt({ min: 1 }).withMessage('ID must be a positive integer')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  const product = products.find(p => p.id === parseInt(req.params.id));
  
  if (!product) {
    return res.status(404).json({ 
      success: false, 
      error: 'Product not found' 
    });
  }
  
  res.json({ success: true, data: product });
});

// POST create new product
app.post('/api/products', [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('category').trim().notEmpty().withMessage('Category is required'),
  body('price').isFloat({ min: 0 }).withMessage('Price must be a positive number'),
  body('stock').isInt({ min: 0 }).withMessage('Stock must be a non-negative integer'),
  body('sku').trim().notEmpty().withMessage('SKU is required'),
  body('description').optional().trim()
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  // Check for duplicate SKU
  const duplicateSku = products.find(p => p.sku === req.body.sku);
  if (duplicateSku) {
    return res.status(409).json({ 
      success: false, 
      error: 'Product with this SKU already exists' 
    });
  }
  
  const newProduct = {
    id: nextId++,
    name: req.body.name,
    category: req.body.category,
    price: parseFloat(req.body.price),
    stock: parseInt(req.body.stock),
    sku: req.body.sku,
    description: req.body.description || '',
    createdAt: new Date().toISOString()
  };
  
  products.push(newProduct);
  
  res.status(201).json({ 
    success: true, 
    data: newProduct,
    message: 'Product created successfully'
  });
});

// PUT update product
app.put('/api/products/:id', [
  param('id').isInt({ min: 1 }).withMessage('ID must be a positive integer'),
  body('name').optional().trim().notEmpty(),
  body('category').optional().trim().notEmpty(),
  body('price').optional().isFloat({ min: 0 }),
  body('stock').optional().isInt({ min: 0 }),
  body('description').optional().trim()
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  const productIndex = products.findIndex(p => p.id === parseInt(req.params.id));
  
  if (productIndex === -1) {
    return res.status(404).json({ 
      success: false, 
      error: 'Product not found' 
    });
  }
  
  // Update only provided fields
  const updatedProduct = {
    ...products[productIndex],
    ...req.body,
    id: products[productIndex].id, // Prevent ID modification
    sku: products[productIndex].sku, // Prevent SKU modification
    updatedAt: new Date().toISOString()
  };
  
  products[productIndex] = updatedProduct;
  
  res.json({ 
    success: true, 
    data: updatedProduct,
    message: 'Product updated successfully'
  });
});

// PATCH update stock
app.patch('/api/products/:id/stock', [
  param('id').isInt({ min: 1 }).withMessage('ID must be a positive integer'),
  body('quantity').isInt().withMessage('Quantity must be an integer'),
  body('operation').isIn(['add', 'subtract', 'set']).withMessage('Operation must be add, subtract, or set')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  const product = products.find(p => p.id === parseInt(req.params.id));
  
  if (!product) {
    return res.status(404).json({ 
      success: false, 
      error: 'Product not found' 
    });
  }
  
  const { quantity, operation } = req.body;
  
  switch (operation) {
    case 'add':
      product.stock += quantity;
      break;
    case 'subtract':
      if (product.stock < quantity) {
        return res.status(400).json({ 
          success: false, 
          error: 'Insufficient stock' 
        });
      }
      product.stock -= quantity;
      break;
    case 'set':
      if (quantity < 0) {
        return res.status(400).json({ 
          success: false, 
          error: 'Stock cannot be negative' 
        });
      }
      product.stock = quantity;
      break;
  }
  
  product.updatedAt = new Date().toISOString();
  
  res.json({ 
    success: true, 
    data: product,
    message: 'Stock updated successfully'
  });
});

// DELETE product
app.delete('/api/products/:id', [
  param('id').isInt({ min: 1 }).withMessage('ID must be a positive integer')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ success: false, errors: errors.array() });
  }
  
  const productIndex = products.findIndex(p => p.id === parseInt(req.params.id));
  
  if (productIndex === -1) {
    return res.status(404).json({ 
      success: false, 
      error: 'Product not found' 
    });
  }
  
  const deletedProduct = products.splice(productIndex, 1)[0];
  
  res.json({ 
    success: true, 
    data: deletedProduct,
    message: 'Product deleted successfully'
  });
});

// GET inventory statistics
app.get('/api/stats', (req, res) => {
  const stats = {
    totalProducts: products.length,
    totalValue: products.reduce((sum, p) => sum + (p.price * p.stock), 0),
    totalStock: products.reduce((sum, p) => sum + p.stock, 0),
    categories: [...new Set(products.map(p => p.category))].length,
    lowStock: products.filter(p => p.stock < 50).length,
    outOfStock: products.filter(p => p.stock === 0).length,
    categoryBreakdown: products.reduce((acc, p) => {
      acc[p.category] = (acc[p.category] || 0) + 1;
      return acc;
    }, {})
  };
  
  res.json({ success: true, data: stats });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    success: false, 
    error: 'Route not found' 
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    success: false, 
    error: 'Internal server error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Only start server if file is run directly (not imported by tests)
if (require.main === module) {
  const server = app.listen(PORT, () => {
    console.log(`🚀 Inventory Management API running on port ${PORT}`);
    console.log(`📊 Metrics available at http://localhost:${PORT}/metrics`);
    console.log(`💚 Health check at http://localhost:${PORT}/health`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  });

  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server gracefully...');
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  });
}

module.exports = app;