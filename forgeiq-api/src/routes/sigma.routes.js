const express = require('express');
const router = express.Router();
const { checkJwt } = require('../middleware/auth.middleware');

// SigmaVault - Phase 3
router.use(checkJwt);
router.use((req, res) => {
  res.status(501).json({
    success: false,
    error: 'SigmaVault not implemented - Phase 3'
  });
});

module.exports = router;
