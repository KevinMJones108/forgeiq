// ForgeIQ Calls Routes
// Objection / "blown-past" detection on post-call transcripts.
// Powered by Claude (Anthropic API) via objectionAnalysisService.

const express = require('express');
const router = express.Router();
const {
  analyzeTranscript,
  isConfigured,
  MODEL
} = require('../services/objectionAnalysisService');
const pipedrive = require('../services/pipedriveService');
const { aiRateLimit } = require('../middleware/aiRateLimit.middleware');

const MAX_TRANSCRIPT_CHARS = 200000; // ~ generous upper bound; guards abuse.

// POST /api/v1/calls/analyze
// Body: {
//   transcript: string,
//   speakerLabels?: string[] | string,
//   dealId?: number|string,    // optional Pipedrive auto-log target
//   personId?: number|string   // optional Pipedrive auto-log target
// }
// Returns: { objections: [...], summary, talkRatio?, model, pipedriveLog? }
// Gated by the guest AI rate limiter (calls the paid Anthropic API).
//
// Pipedrive auto-log is ADDITIVE + FAIL-OPEN: it only fires when a target
// (dealId/personId) is supplied AND PIPEDRIVE_API_TOKEN is configured. Any
// Pipedrive failure is swallowed — the analysis response is returned regardless.
// Guests with no target / no token get exactly today's behaviour.
router.post('/analyze', aiRateLimit, async (req, res, next) => {
  try {
    const { transcript, speakerLabels, dealId, personId } = req.body || {};

    // --- validation ---
    if (typeof transcript !== 'string' || transcript.trim().length === 0) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'transcript (non-empty string) is required'
      });
    }
    if (transcript.length > MAX_TRANSCRIPT_CHARS) {
      return res.status(400).json({
        success: false,
        data: null,
        error: `transcript exceeds maximum length of ${MAX_TRANSCRIPT_CHARS} characters`
      });
    }
    if (
      speakerLabels !== undefined &&
      !Array.isArray(speakerLabels) &&
      typeof speakerLabels !== 'string'
    ) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'speakerLabels must be an array of strings or a string'
      });
    }

    // --- config gate ---
    if (!isConfigured()) {
      return res.status(503).json({
        success: false,
        data: null,
        error: 'analysis not configured'
      });
    }

    const analysis = await analyzeTranscript(transcript, speakerLabels);

    // --- optional, fail-open Pipedrive auto-log ---
    // Only attempt when a target is supplied AND Pipedrive is configured.
    // A failure here must NEVER fail the analyze response.
    let pipedriveLog;
    const hasTarget = Boolean(dealId || personId);
    if (hasTarget && pipedrive.isConfigured()) {
      try {
        const result = await pipedrive.logCall({
          summary: analysis.summary || '',
          objections: analysis.objections || [],
          dealId,
          personId
        });
        pipedriveLog = {
          logged: true,
          configured: true,
          noteId: result.noteId,
          target: result.target
        };
      } catch (pdErr) {
        // Swallow — log for diagnostics, return the analysis anyway.
        console.error('calls/analyze pipedrive auto-log failed:', pdErr.message);
        pipedriveLog = {
          logged: false,
          configured: true,
          error: 'pipedrive log failed (upstream)'
        };
      }
    } else if (hasTarget && !pipedrive.isConfigured()) {
      pipedriveLog = { logged: false, configured: false };
    }
    // No target -> pipedriveLog stays undefined -> response identical to today.

    const data = { ...analysis, model: MODEL };
    if (pipedriveLog !== undefined) data.pipedriveLog = pipedriveLog;

    return res.json({
      success: true,
      data,
      error: null
    });
  } catch (error) {
    // Map known service error codes to clean client responses.
    if (error && error.statusCode === 503) {
      return res.status(503).json({
        success: false,
        data: null,
        error: 'analysis not configured'
      });
    }
    if (error && error.statusCode === 502) {
      return res.status(502).json({
        success: false,
        data: null,
        error: 'objection analysis failed (upstream)'
      });
    }
    console.error('calls/analyze error:', error.message);
    return next(error);
  }
});

module.exports = router;
