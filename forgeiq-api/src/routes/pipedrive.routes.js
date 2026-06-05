// ForgeIQ Pipedrive Routes
// Auto-log a call summary + detected objections to Pipedrive as a Note.

const express = require('express');
const router = express.Router();
const pipedrive = require('../services/pipedriveService');

// POST /api/v1/pipedrive/log-call
// Body: {
//   summary: string,
//   objections?: Array<{text,severity,addressed,blewPast,suggestedResponse}>,
//   dealId?: number|string,
//   personId?: number|string
// }
// At least one of dealId / personId required.
//
// If PIPEDRIVE_API_TOKEN is absent -> no-op gracefully (200, configured:false).
router.post('/log-call', async (req, res, next) => {
  try {
    const { summary, objections, dealId, personId } = req.body || {};

    // --- validation ---
    if (summary !== undefined && typeof summary !== 'string') {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'summary must be a string'
      });
    }
    if (objections !== undefined && !Array.isArray(objections)) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'objections must be an array'
      });
    }
    if (!dealId && !personId) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'dealId or personId is required'
      });
    }

    // --- graceful no-op when not configured ---
    if (!pipedrive.isConfigured()) {
      return res.status(200).json({
        success: true,
        data: {
          logged: false,
          configured: false,
          message: 'pipedrive not configured'
        },
        error: null
      });
    }

    const result = await pipedrive.logCall({
      summary: summary || '',
      objections: objections || [],
      dealId,
      personId
    });

    return res.json({
      success: true,
      data: {
        logged: true,
        configured: true,
        noteId: result.noteId,
        target: result.target
      },
      error: null
    });
  } catch (error) {
    if (error && error.statusCode === 400) {
      return res.status(400).json({
        success: false,
        data: null,
        error: error.message
      });
    }
    if (error && error.statusCode === 502) {
      return res.status(502).json({
        success: false,
        data: null,
        error: 'pipedrive log failed (upstream)'
      });
    }
    console.error('pipedrive/log-call error:', error.message);
    return next(error);
  }
});

module.exports = router;
