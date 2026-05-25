require('dotenv').config();
const app = require('./app');
const { migrate } = require('./db/migrate');

const PORT = process.env.PORT || 3001;

// Run migration then start server
async function start() {
  try {
    // Skip migration if DATABASE_URL not set (PostgreSQL not installed)
    if (process.env.DATABASE_URL) {
      await migrate();
    } else {
      console.log('⚠️  Skipping migration (DATABASE_URL not set)');
    }

    app.listen(PORT, () => {
      console.log(`🚀 ForgeIQ API running on port ${PORT}`);
      console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
