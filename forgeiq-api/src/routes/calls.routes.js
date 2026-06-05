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

const MAX_TRANSCRIPT_CHARS = 200000; // ~ generous upper bound; guards abuse.

// POST /api/v1/calls/analyze
// Body: { transcript: string, speakerLabels?: string[] | string }
// Returns: { objections: [...], summary, talkRatio? }
router.post('/analyze', async (req, res, next) => {
  try {
    const { transcript, speakerLabels } = req.body || {};

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

    return res.json({
      success: true,
      data: { ...analysis, model: MODEL },
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
