const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

async function migrate() {
  try {
    const schemaSQL = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    await pool.query(schemaSQL);
    console.log('✅ Database schema migrated');
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    throw error;
  }
}

module.exports = { migrate };
