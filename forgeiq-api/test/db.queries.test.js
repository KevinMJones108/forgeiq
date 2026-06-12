// Schema/route contract test — runs only when TEST_DATABASE_URL is set.
// Executes every SQL statement used by the route files against a freshly
// migrated schema, so column renames can never silently break an endpoint.
const { test, skip } = require('node:test');
const assert = require('node:assert');

const TEST_DB = process.env.TEST_DATABASE_URL;

if (!TEST_DB) {
  skip('TEST_DATABASE_URL not set — skipping DB contract tests');
} else {
  process.env.DATABASE_URL = TEST_DB;
  const { migrate } = require('../src/db/migrate');
  const { pool } = require('../src/db');

  test('every route SQL statement runs against the migrated schema', async (t) => {
    await migrate();

    // auth.routes.js
    const u = await pool.query(
      `INSERT INTO users (auth0_sub, email, name) VALUES ($1,$2,$3)
       RETURNING id, auth0_sub, email, name, created_at`,
      [`auth0|test-${Date.now()}`, 'test@example.com', 'Test User']);
    const userId = u.rows[0].id;
    t.after(() => pool.query('DELETE FROM users WHERE id = $1', [userId]).then(() => pool.end()));

    await pool.query('INSERT INTO user_subscriptions (user_id, voice_core_enabled) VALUES ($1,true)', [userId]);
    const me = await pool.query(
      `SELECT u.id, u.email, u.name, u.created_at,
         s.voice_core_enabled, s.idea_vault_enabled, s.sigma_vault_enabled,
         s.sales_forge_enabled, s.doe_enabled, s.apex_script_enabled
       FROM users u LEFT JOIN user_subscriptions s ON u.id = s.user_id WHERE u.auth0_sub = $1`,
      [u.rows[0].auth0_sub]);
    assert.strictEqual(me.rows[0].voice_core_enabled, true);

    // voice.routes.js
    const r = await pool.query(
      `INSERT INTO recordings (user_id, title, audio_duration_sec) VALUES ($1,$2,$3)
       RETURNING id, title, audio_duration_sec, created_at`, [userId, 'Test call', 90]);
    const recId = r.rows[0].id;

    await pool.query(
      `SELECT id, title, audio_duration_sec, created_at FROM recordings
       WHERE user_id = $1 AND deleted_at IS NULL ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
      [userId, 20, 0]);

    const tr = await pool.query(
      `INSERT INTO transcripts (recording_id, transcript_text, source_language, translated_text, target_language)
       VALUES ($1,$2,$3,$4,$5)
       RETURNING id, transcript_text, source_language, translated_text, target_language, created_at`,
      [recId, 'Hello world.', 'en', null, null]);

    const joined = await pool.query(
      `SELECT r.id, r.title, r.audio_duration_sec, r.created_at,
         t.transcript_text, t.source_language, t.translated_text, t.target_language
       FROM recordings r LEFT JOIN transcripts t ON r.id = t.recording_id
       WHERE r.id = $1 AND r.user_id = $2 AND r.deleted_at IS NULL`, [recId, userId]);
    assert.strictEqual(joined.rows[0].transcript_text, 'Hello world.');

    await pool.query(
      `SELECT t.id, t.transcript_text, t.source_language, t.translated_text, t.target_language, t.created_at
       FROM transcripts t JOIN recordings r ON t.recording_id = r.id
       WHERE t.id = $1 AND r.user_id = $2 AND r.deleted_at IS NULL`, [tr.rows[0].id, userId]);

    await pool.query(
      `UPDATE recordings SET title = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL
       RETURNING id, title, audio_duration_sec, created_at`, ['Renamed', recId, userId]);

    // ai.routes.js
    const cs = await pool.query(
      `INSERT INTO call_summaries
         (user_id, recording_id, summary, went_well, learning_points, blown_past,
          commitments, next_step, call_score, talk_time_rep_pct, talk_time_prospect_pct,
          re_engagement_candidate)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING id, created_at`,
      [userId, recId, 'Summary.', '[]', '[]', '[]', '[]', 'Next', 7, 38, 62, false]);

    await pool.query(
      `SELECT id, recording_id, summary, went_well, learning_points, blown_past,
              commitments, next_step, call_score, talk_time_rep_pct,
              talk_time_prospect_pct, re_engagement_candidate, created_at
       FROM call_summaries WHERE user_id = $1 ORDER BY created_at DESC LIMIT $2 OFFSET $3`,
      [userId, 20, 0]);

    const stats = await pool.query(
      `SELECT COUNT(*)::int AS total_calls, ROUND(AVG(call_score),1)::float AS avg_call_score,
              ROUND(AVG(talk_time_rep_pct))::int AS avg_talk_time_rep_pct,
              COUNT(*) FILTER (WHERE re_engagement_candidate)::int AS re_engagement_count
       FROM call_summaries WHERE user_id = $1`, [userId]);
    assert.strictEqual(stats.rows[0].total_calls, 1);

    // crm.routes.js
    await pool.query(
      `SELECT id, summary, went_well, learning_points, blown_past, commitments,
              next_step, call_score, re_engagement_candidate
       FROM call_summaries WHERE id = $1 AND user_id = $2`, [cs.rows[0].id, userId]);
    await pool.query(
      'UPDATE call_summaries SET pipedrive_activity_id = $1 WHERE id = $2 AND user_id = $3',
      ['123', cs.rows[0].id, userId]);

    // soft delete
    const del = await pool.query(
      `UPDATE recordings SET deleted_at = NOW()
       WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL RETURNING id`, [recId, userId]);
    assert.strictEqual(del.rows.length, 1);
  });
}
