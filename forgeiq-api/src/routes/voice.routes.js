const express = require('express');
const router = express.Router();
const { query } = require('../db');
const { checkJwt } = require('../middleware/auth.middleware');
const { success, error } = require('../utils/response');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

// Helper to get user_id from JWT
async function getUserId(auth0_sub) {
  const result = await query('SELECT id FROM users WHERE auth0_sub = $1', [auth0_sub]);
  if (result.rows.length === 0) throw new Error('User not found');
  return result.rows[0].id;
}

// GET /api/v1/voice/recordings
// List recordings with pagination
router.get('/recordings', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const result = await query(
      `SELECT id, title, audio_duration_sec, created_at
       FROM recordings
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [user_id, limit, offset]
    );

    const countResult = await query(
      'SELECT COUNT(*) FROM recordings WHERE user_id = $1 AND deleted_at IS NULL',
      [user_id]
    );

    return res.json(success({
      recordings: result.rows,
      total: parseInt(countResult.rows[0].count),
      page,
      limit
    }));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/voice/recordings
// Create recording
router.post('/recordings', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { title, audio_duration_sec } = req.body;

    if (!title || !audio_duration_sec) {
      return res.status(400).json(error('title and audio_duration_sec required'));
    }

    const result = await query(
      `INSERT INTO recordings (user_id, title, audio_duration_sec)
       VALUES ($1, $2, $3)
       RETURNING id, title, audio_duration_sec, created_at`,
      [user_id, title, audio_duration_sec]
    );

    return res.status(201).json(success({ recording: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/voice/recordings/:id
// Get single recording + transcript
router.get('/recordings/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { id } = req.params;

    const result = await query(
      `SELECT
         r.id, r.title, r.audio_duration_sec, r.created_at,
         t.transcript_text, t.source_language, t.translated_text, t.target_language
       FROM recordings r
       LEFT JOIN transcripts t ON r.id = t.recording_id
       WHERE r.id = $1 AND r.user_id = $2 AND r.deleted_at IS NULL`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Recording not found'));
    }

    return res.json(success({ recording: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// PUT /api/v1/voice/recordings/:id
// Update title
router.put('/recordings/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { id } = req.params;
    const { title } = req.body;

    if (!title) {
      return res.status(400).json(error('title required'));
    }

    const result = await query(
      `UPDATE recordings
       SET title = $1
       WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL
       RETURNING id, title, audio_duration_sec, created_at`,
      [title, id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Recording not found'));
    }

    return res.json(success({ recording: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/voice/recordings/:id
// Soft delete
router.delete('/recordings/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { id } = req.params;

    const result = await query(
      `UPDATE recordings
       SET deleted_at = NOW()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
       RETURNING id`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Recording not found'));
    }

    return res.json(success({ deleted: true }));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/voice/transcripts
// Save transcript
router.post('/transcripts', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { recording_id, transcript_text, source_language, translated_text, target_language } = req.body;

    if (!recording_id || !transcript_text || !source_language) {
      return res.status(400).json(error('recording_id, transcript_text, source_language required'));
    }

    // Verify recording belongs to user
    const recordingCheck = await query(
      'SELECT id FROM recordings WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [recording_id, user_id]
    );

    if (recordingCheck.rows.length === 0) {
      return res.status(404).json(error('Recording not found'));
    }

    const result = await query(
      `INSERT INTO transcripts (recording_id, user_id, transcript_text, source_language, translated_text, target_language)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, transcript_text, source_language, translated_text, target_language, created_at`,
      [recording_id, user_id, transcript_text, source_language, translated_text, target_language]
    );

    return res.status(201).json(success({ transcript: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/voice/transcripts/:id
// Get transcript
router.get('/transcripts/:id', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { id } = req.params;

    const result = await query(
      `SELECT t.id, t.transcript_text, t.source_language, t.translated_text, t.target_language, t.created_at
       FROM transcripts t
       JOIN recordings r ON t.recording_id = r.id
       WHERE t.id = $1 AND r.user_id = $2 AND r.deleted_at IS NULL`,
      [id, user_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json(error('Transcript not found'));
    }

    return res.json(success({ transcript: result.rows[0] }));
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/voice/tts
// ElevenLabs TTS proxy - streams audio back to iOS
router.post('/tts', checkJwt, async (req, res, next) => {
  try {
    const { text, voice_id } = req.body;

    if (!text || !voice_id) {
      return res.status(400).json(error('text and voice_id required'));
    }

    if (!process.env.ELEVEN_LABS_API_KEY) {
      return res.status(500).json(error('ElevenLabs API key not configured'));
    }

    // Call ElevenLabs API
    const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voice_id}`, {
      method: 'POST',
      headers: {
        'xi-api-key': process.env.ELEVEN_LABS_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_multilingual_v2',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75
        }
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('ElevenLabs API error:', response.status, errorText);
      return res.status(response.status).json(error('ElevenLabs API error'));
    }

    // Stream audio back to iOS
    res.setHeader('Content-Type', 'audio/mpeg');
    response.body.pipe(res);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
