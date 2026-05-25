function errorHandler(err, req, res, next) {
  if (err.name === 'UnauthorizedError') {
    return res.status(401).json({
      success: false,
      error: 'Invalid or missing authentication token'
    });
  }

  console.error('Error:', err);
  const statusCode = err.statusCode || 500;
  const message = process.env.NODE_ENV === 'production'
    ? 'Internal server error'
    : err.message;

  res.status(statusCode).json({
    success: false,
    error: message
  });
}

module.exports = errorHandler;
