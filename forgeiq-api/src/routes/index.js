const express = require('express');
const router = express.Router();

// Mount all module routes
router.use('/auth', require('./auth.routes'));
router.use('/voice', require('./voice.routes'));
router.use('/ai', require('./ai.routes'));
router.use('/crm', require('./crm.routes'));
router.use('/ideas', require('./ideas.routes'));
router.use('/sigma', require('./sigma.routes'));
router.use('/forge', require('./forge.routes'));
router.use('/vapi', require('./vapi.routes'));

module.exports = router;
