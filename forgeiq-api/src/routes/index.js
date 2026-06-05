const express = require('express');
const router = express.Router();

// Mount all module routes
router.use('/auth', require('./auth.routes'));
router.use('/voice', require('./voice.routes'));
router.use('/ai', require('./ai.routes')); // Session 12
router.use('/products', require('./products.routes')); // Session 12
router.use('/ideas', require('./ideas.routes'));
router.use('/sigma', require('./sigma.routes'));
router.use('/forge', require('./forge.routes'));
router.use('/vapi', require('./vapi.routes'));
router.use('/scripts', require('./scripts.routes')); // Session 11
router.use('/calls', require('./calls.routes')); // Objection / blown-past detection (Claude)
router.use('/pipedrive', require('./pipedrive.routes')); // Pipedrive auto-log

module.exports = router;
