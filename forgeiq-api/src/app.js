const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();

// Security middleware
app.use(helmet());

// CORS - allow all in development
app.use(cors({
  origin: process.env.NODE_ENV === 'production'
    ? process.env.ALLOWED_ORIGINS?.split(',')
    : '*'
}));

// Request parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Logging
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

// Health check endpoint (no auth required)
app.get('/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'ok',
      version: '1.0.0',
      timestamp: new Date().toISOString()
    }
  });
});

// API routes
app.use('/api/v1', require('./routes'));

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Route not found'
  });
});

// Global error handler
const errorHandler = require('./middleware/errorHandler');
app.use(errorHandler);

module.exports = app;
