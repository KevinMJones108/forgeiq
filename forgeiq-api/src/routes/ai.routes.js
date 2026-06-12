const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { checkJwt } = require('../middleware/auth.middleware');
const { success, error } = require('../utils/response');
const { generateCallSummary, isReEngagementCandidate } = require('../services/callSummaryService');

// Helper to get user_id from JWT
async function getUserId(auth0_sub) {
  const result = await pool.query('SELECT id FROM users WHERE auth0_sub = $1', [auth0_sub]);
  if (result.rows.length === 0) throw new Error('User not found');
  return result.rows[0].id;
}

// POST /api/v1/ai/call-summary
// Generate AI Call Summary + Blown Past analysis for a transcript (Session 10)
router.post('/call-summary', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { recording_id, transcript } = req.body;

    let transcriptText = transcript;

    // If only a recording_id is supplied, load its transcript (user-scoped)
    if (!transcriptText && recording_id) {
      const result = await pool.query(
        `SELECT t.transcript_text
         FROM transcripts t
         JOIN recordings r ON t.recording_id = r.id
         WHERE r.id = $1 AND r.user_id = $2 AND r.deleted_at IS NULL
         ORDER BY t.created_at DESC
         LIMIT 1`,
        [recording_id, user_id]
      );
      if (result.rows.length === 0) {
        return res.status(404).json(error('Recording or transcript not found'));
      }
      transcriptText = result.rows[0].transcript_text;
    }

    if (!transcriptText) {
      return res.status(400).json(error('transcript or recording_id required'));
    }

    // If recording_id was supplied alongside transcript, verify ownership
    if (recording_id && transcript) {
      const check = await pool.query(
        'SELECT id FROM recordings WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
        [recording_id, user_id]
      );
      if (check.rows.length === 0) {
        return res.status(404).json(error('Recording not found'));
      }
    }

    const summary = await generateCallSummary(transcriptText);
    const reEngagement = isReEngagementCandidate(summary);

    const insert = await pool.query(
      `INSERT INTO call_summaries
         (user_id, recording_id, summary, went_well, learning_points, blown_past,
          commitments, next_step, call_score, talk_time_rep_pct, talk_time_prospect_pct,
          re_engagement_candidate)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
       RETURNING id, created_at`,
      [
        user_id,
        recording_id || null,
        summary.summary,
        JSON.stringify(summary.went_well),
        JSON.stringify(summary.learning_points),
        JSON.stringify(summary.blown_past),
        JSON.stringify(summary.commitments),
        summary.next_step,
        summary.call_score,
        summary.talk_time_rep_pct,
        summary.talk_time_prospect_pct,
        reEngagement
      ]
    );

    return res.status(201).json(success({
      call_summary: {
        id: insert.rows[0].id,
        recording_id: recording_id || null,
        ...summary,
        re_engagement_candidate: reEngagement,
        created_at: insert.rows[0].created_at
      }
    }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/ai/call-summaries
// Paginated list of the user's call summaries (powers rep dashboard)
router.get('/call-summaries', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT id, recording_id, summary, went_well, learning_points, blown_past,
              commitments, next_step, call_score, talk_time_rep_pct,
              talk_time_prospect_pct, re_engagement_candidate, created_at
       FROM call_summaries
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [user_id, limit, offset]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*) FROM call_summaries WHERE user_id = $1',
      [user_id]
    );

    return res.json(success({
      call_summaries: result.rows,
      total: parseInt(countResult.rows[0].count),
      page,
      limit
    }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/ai/rep-stats
// Aggregate stats for the rep dashboard (Owen vs Kevin — per-user only)
router.get('/rep-stats', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);

    const result = await pool.query(
      `SELECT
         COUNT(*)::int AS total_calls,
         ROUND(AVG(call_score), 1)::float AS avg_call_score,
         ROUND(AVG(talk_time_rep_pct))::int AS avg_talk_time_rep_pct,
         COUNT(*) FILTER (WHERE re_engagement_candidate)::int AS re_engagement_count
       FROM call_summaries
       WHERE user_id = $1`,
      [user_id]
    );

    return res.json(success({ stats: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
