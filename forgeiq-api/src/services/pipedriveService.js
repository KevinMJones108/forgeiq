// PipedriveService — Session 10
// Auto-logs call activity, deal notes, and follow-up tasks to Pipedrive.
// API token lives server-side only (PIPEDRIVE_API_TOKEN).

const PIPEDRIVE_BASE_URL = 'https://api.pipedrive.com/v1';

function requireToken() {
  if (!process.env.PIPEDRIVE_API_TOKEN) {
    const err = new Error('Pipedrive API token not configured');
    err.statusCode = 500;
    throw err;
  }
  return process.env.PIPEDRIVE_API_TOKEN;
}

async function pipedrivePost(path, body) {
  const token = requireToken();
  const response = await fetch(`${PIPEDRIVE_BASE_URL}${path}?api_token=${token}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  });

  const result = await response.json().catch(() => null);
  if (!response.ok || !result?.success) {
    console.error('Pipedrive API error:', response.status, path);
    const err = new Error('Pipedrive API error');
    err.statusCode = 502;
    throw err;
  }
  return result.data;
}

// 1. Call activity (done) with summary as the note body
async function createCallActivity({ contactName, date, duration, note, dealId, personId }) {
  return pipedrivePost('/activities', {
    subject: `ForgeIQ Call — ${contactName} ${date}`,
    type: 'call',
    duration,
    note,
    done: true,
    ...(dealId ? { deal_id: dealId } : {}),
    ...(personId ? { person_id: personId } : {})
  });
}

// 2. Note on the deal (blown past items + learning points)
async function createDealNote({ content, dealId, personId }) {
  return pipedrivePost('/notes', {
    content,
    ...(dealId ? { deal_id: dealId } : {}),
    ...(personId ? { person_id: personId } : {})
  });
}

// 3. Follow-up task — one per commitment, due tomorrow by default
async function createFollowUpTask({ subject, dueDate, dealId, personId }) {
  return pipedrivePost('/activities', {
    subject,
    type: 'task',
    due_date: dueDate,
    done: false,
    ...(dealId ? { deal_id: dealId } : {}),
    ...(personId ? { person_id: personId } : {})
  });
}

// Re-engagement loop: task at day +7 for low-score calls
async function createReEngagementTask({ contactName, dealId, personId }) {
  const due = new Date();
  due.setDate(due.getDate() + 7);
  return createFollowUpTask({
    subject: `Re-engage ${contactName} — ForgeIQ improved script ready`,
    dueDate: due.toISOString().slice(0, 10),
    dealId,
    personId
  });
}

module.exports = {
  createCallActivity,
  createDealNote,
  createFollowUpTask,
  createReEngagementTask
};
