const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
require('dotenv').config();

// Import modules
const connectDB = require('./config/db');
const bookRoutes = require('./routes/bookRoutes');
const corsOptions = require('./middleware/cors');
const errorHandler = require('./middleware/errorHandler');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// ============================================
// Middleware Configuration
// ============================================

// 1. CORS Middleware - Enable cross-origin requests from frontend
app.use(cors(corsOptions));
console.log('✅ CORS middleware configured');

// 2. JSON Parser Middleware - Parse incoming JSON request bodies
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ limit: '10mb', extended: true }));
console.log('✅ JSON parser middleware configured');

// 3. Request Logging Middleware
app.use((req, res, next) => {
  console.log(`\n📨 ${new Date().toLocaleTimeString()} - ${req.method} ${req.path}`);
  console.log(`   Headers: ${JSON.stringify(req.headers)}`);
  if (Object.keys(req.body).length > 0) {
    console.log(`   Body: ${JSON.stringify(req.body)}`);
  }
  next();
});

// ============================================
// Routes Configuration
// ============================================

// API Routes
app.use('/api', bookRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'Server is running',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'Library Management System - Backend API',
    version: '1.0.0',
    endpoints: {
      'GET /api/books': 'Get all books',
      'POST /api/books': 'Add a new book',
      'GET /api/books/:id': 'Get a single book',
      'PUT /api/books/:id': 'Update a book',
      'DELETE /api/books/:id': 'Delete a book',
      'GET /api/stats/summary': 'Get library statistics',
      'GET /api/health': 'Health check',
    },
  });
});

// 404 Handler
app.use((req, res) => {
  console.log(`⚠️  404 - Route not found: ${req.method} ${req.path}`);
  res.status(404).json({
    success: false,
    error: 'Route not found',
    message: `The endpoint ${req.method} ${req.path} does not exist`,
    availableEndpoints: {
      'GET /api/books': 'Get all books',
      'POST /api/books': 'Add a new book',
      'GET /api/books/:id': 'Get a single book',
      'PUT /api/books/:id': 'Update a book',
      'DELETE /api/books/:id': 'Delete a book',
      'GET /api/stats/summary': 'Get library statistics',
      'GET /api/health': 'Health check',
    },
  });
});

// Error Handling Middleware
app.use(errorHandler);

// ============================================
// Database Connection & Server Start
// ============================================

const startServer = async () => {
  try {
    console.log('\n🚀 Starting Library Management Backend Server...\n');

    // Connect to MongoDB
    await connectDB();

    // Start Express server
    const server = app.listen(PORT, () => {
      console.log(`\n✅ Server is running on http://localhost:${PORT}`);
      console.log(`📊 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log('\n📖 Available Endpoints:');
      console.log('   GET    /api/books              - Get all books');
      console.log('   POST   /api/books              - Add a new book');
      console.log('   GET    /api/books/:id          - Get single book');
      console.log('   PUT    /api/books/:id          - Update a book');
      console.log('   DELETE /api/books/:id          - Delete a book');
      console.log('   GET    /api/stats/summary      - Get statistics');
      console.log('   GET    /api/health             - Health check');
      console.log('\n💡 Tip: Frontend should be running on http://localhost:3000\n');
    });

    // Handle server errors
    server.on('error', (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(
          `❌ Port ${PORT} is already in use. Please use a different port or kill the process using this port.`
        );
        process.exit(1);
      } else {
        console.error('❌ Server error:', error);
        process.exit(1);
      }
    });

    // Graceful shutdown
    process.on('SIGTERM', () => {
      console.log('\n📛 SIGTERM received. Shutting down gracefully...');
      server.close(() => {
        console.log('✅ Server closed');
        mongoose.connection.close();
        console.log('✅ Database connection closed');
        process.exit(0);
      });
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
};

// Start the server
startServer();

module.exports = app;
