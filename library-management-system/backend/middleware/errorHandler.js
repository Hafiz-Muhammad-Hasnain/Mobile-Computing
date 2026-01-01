// Global Error Handling Middleware
const errorHandler = (err, req, res, next) => {
  console.error('❌ Error:', err.message);
  
  // Default error
  let error = {
    statusCode: err.statusCode || 500,
    message: err.message || 'Server Error',
  };
  
  // Handle Mongoose validation errors
  if (err.name === 'ValidationError') {
    error.statusCode = 400;
    error.message = Object.values(err.errors)
      .map((e) => e.message)
      .join(', ');
  }
  
  // Handle Mongoose duplicate key errors
  if (err.code === 11000) {
    error.statusCode = 409;
    const field = Object.keys(err.keyValue)[0];
    error.message = `${field} must be unique`;
  }
  
  // Handle Mongoose cast errors
  if (err.name === 'CastError') {
    error.statusCode = 400;
    error.message = 'Invalid ID format';
  }
  
  res.status(error.statusCode).json({
    success: false,
    error: error.message,
  });
};

module.exports = errorHandler;
