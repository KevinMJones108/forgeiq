const express = require('express');
const router = express.Router();
const { checkJwt } = require('../middleware/auth.middleware');

// IdeaVault - Phase 2
router.use(checkJwt);
router.use((req, res) => {
  res.status(501).json({
    success: false,
    error: 'IdeaVault not implemented - Phase 2'
  });
});

module.exports = router;
