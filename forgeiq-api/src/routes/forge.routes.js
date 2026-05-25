const express = require('express');
const router = express.Router();
const { checkJwt } = require('../middleware/auth.middleware');

// SalesForge - Phase 4
router.use(checkJwt);
router.use((req, res) => {
  res.status(501).json({
    success: false,
    error: 'SalesForge not implemented - Phase 4'
  });
});

module.exports = router;
