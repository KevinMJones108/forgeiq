const express = require('express');
const router = express.Router();
const { pool } = require('../db');
const { checkJwt } = require('../middleware/auth.middleware');
const { success, error } = require('../utils/response');
const pipedrive = require('../services/pipedriveService');

// Helper to get user_id from JWT
async function getUserId(auth0_sub) {
  const result = await pool.query('SELECT id FROM users WHERE auth0_sub = $1', [auth0_sub]);
  if (result.rows.length === 0) throw new Error('User not found');
  return result.rows[0].id;
}

// POST /api/v1/crm/log-call
// Pipedrive auto-log (Session 10): call activity + deal note + follow-up tasks
router.post('/log-call', checkJwt, async (req, res, next) => {
  try {
    const user_id = await getUserId(req.auth.sub);
    const { call_summary_id, contact_name, duration, deal_id, person_id } = req.body;

    if (!call_summary_id || !contact_name) {
      return res.status(400).json(error('call_summary_id and contact_name required'));
    }

    // Load the summary (user-scoped)
    const summaryResult = await pool.query(
      `SELECT id, summary, went_well, learning_points, blown_past, commitments,
              next_step, call_score, re_engagement_candidate
       FROM call_summaries
       WHERE id = $1 AND user_id = $2`,
      [call_summary_id, user_id]
    );

    if (summaryResult.rows.length === 0) {
      return res.status(404).json(error('Call summary not found'));
    }

    const cs = summaryResult.rows[0];
    const dateString = new Date().toISOString().slice(0, 10);

    // 1. Call activity with full summary as the note
    const noteBody = [
      cs.summary,
      '',
      `Call score: ${cs.call_score ?? 'n/a'}/10`,
      cs.next_step ? `Next step: ${cs.next_step}` : null
    ].filter(Boolean).join('\n');

    const activity = await pipedrive.createCallActivity({
      contactName: contact_name,
      date: dateString,
      duration: duration || null,
      note: noteBody,
      dealId: deal_id,
      personId: person_id
    });

    // 2. Deal note: blown past items + learning points
    const blownPastLines = (cs.blown_past || []).map(
      (b) => `[${b.signal_type}] ${b.timestamp} — "${b.prospect_said}" → ${b.suggested_response}`
    );
    const learningLines = (cs.learning_points || []).map((l) => `- ${l}`);
    const noteContent = [
      '<b>Blown Past Signals</b>',
      ...(blownPastLines.length ? blownPastLines : ['None detected']),
      '',
      '<b>Learning Points</b>',
      ...(learningLines.length ? learningLines : ['None'])
    ].join('<br>');

    await pipedrive.createDealNote({
      content: noteContent,
      dealId: deal_id,
      personId: person_id
    });

    // 3. Follow-up task per commitment (due tomorrow)
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dueDate = tomorrow.toISOString().slice(0, 10);

    const commitments = cs.commitments || [];
    for (const commitment of commitments) {
      await pipedrive.createFollowUpTask({
        subject: commitment.text,
        dueDate,
        dealId: deal_id,
        personId: person_id
      });
    }

    // 4. Re-engagement loop: low-score calls get a day +7 task
    if (cs.re_engagement_candidate) {
      await pipedrive.createReEngagementTask({
        contactName: contact_name,
        dealId: deal_id,
        personId: person_id
      });
    }

    // Record the Pipedrive activity id on the summary
    await pool.query(
      'UPDATE call_summaries SET pipedrive_activity_id = $1 WHERE id = $2 AND user_id = $3',
      [String(activity.id), call_summary_id, user_id]
    );

    return res.status(201).json(success({
      logged: true,
      pipedrive_activity_id: activity.id,
      tasks_created: commitments.length,
      re_engagement_task: cs.re_engagement_candidate
    }));
  } catch (err) {
    next(err);
  }
});

module.exports = router;
