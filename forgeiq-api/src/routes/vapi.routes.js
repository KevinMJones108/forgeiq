const express = require('express');
const router = express.Router();
const { checkJwt } = require('../middleware/auth.middleware');

// Vapi Voice Agent - Phase 2
router.use(checkJwt);
router.use((req, res) => {
  res.status(501).json({
    success: false,
    error: 'Vapi Voice Agent not implemented - Phase 2'
  });
});

module.exports = router;
