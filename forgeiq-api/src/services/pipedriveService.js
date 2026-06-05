// ForgeIQ Pipedrive client
// Logs call summaries + detected objections to Pipedrive as a Note attached to
// a deal (or person).
//
// Config:
//   PIPEDRIVE_API_TOKEN  (required to be "configured")
//   PIPEDRIVE_DOMAIN     (optional; the company subdomain, e.g. "mycompany"
//                         for mycompany.pipedrive.com. Defaults to api domain.)
//
// If the token is absent, isConfigured() returns false and callers should
// no-op gracefully rather than error.

const DEFAULT_HOST = 'https://api.pipedrive.com';

/**
 * @returns {boolean} true if PIPEDRIVE_API_TOKEN is present.
 */
function isConfigured() {
  return Boolean(process.env.PIPEDRIVE_API_TOKEN);
}

/**
 * Resolve the Pipedrive API base host.
 * If PIPEDRIVE_DOMAIN is set (subdomain), use https://<domain>.pipedrive.com,
 * otherwise the generic api.pipedrive.com host.
 */
function getBaseHost() {
  const domain = process.env.PIPEDRIVE_DOMAIN;
  if (domain && domain.trim()) {
    const d = domain.trim();
    // Accept either "mycompany" or a full host.
    if (d.startsWith('http://') || d.startsWith('https://')) return d.replace(/\/$/, '');
    if (d.includes('.')) return `https://${d}`;
    return `https://${d}.pipedrive.com`;
  }
  return DEFAULT_HOST;
}

/**
 * Build the markdown content for a Pipedrive note from a call summary + objections.
 * @param {object} params
 * @param {string} params.summary
 * @param {Array}  params.objections
 * @returns {string} HTML/markdown-ish content (Pipedrive notes accept HTML).
 */
function buildNoteContent({ summary, objections }) {
  const lines = [];
  lines.push('<b>ForgeIQ Call Analysis</b>');
  if (summary) {
    lines.push('');
    lines.push(escapeHtml(summary));
  }

  const list = Array.isArray(objections) ? objections : [];
  if (list.length > 0) {
    lines.push('');
    lines.push('<b>Objections detected:</b>');
    lines.push('<ul>');
    for (const o of list) {
      const status = o && o.blewPast ? 'BLEW PAST' : 'addressed';
      const sev = o && o.severity ? String(o.severity).toUpperCase() : 'MED';
      const text = o && o.text ? escapeHtml(String(o.text)) : '(objection)';
      let li = `<li>[${sev}] ${text} — <b>${status}</b>`;
      if (o && o.blewPast && o.suggestedResponse) {
        li += `<br/><i>Suggested: ${escapeHtml(String(o.suggestedResponse))}</i>`;
      }
      li += '</li>';
      lines.push(li);
    }
    lines.push('</ul>');
  }

  lines.push('');
  lines.push(`<i>Logged by ForgeIQ on ${new Date().toISOString()}</i>`);
  return lines.join('\n');
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

/**
 * Create a Note in Pipedrive attached to a deal and/or person.
 * At least one of dealId / personId is required by Pipedrive.
 *
 * @param {object} params
 * @param {string} params.content        Note content (HTML allowed).
 * @param {number|string} [params.dealId]
 * @param {number|string} [params.personId]
 * @returns {Promise<object>} { id, ...pipedriveData }
 * @throws {Error} with .statusCode for caller mapping.
 */
async function createNote({ content, dealId, personId }) {
  if (!isConfigured()) {
    const err = new Error('pipedrive not configured');
    err.statusCode = 503;
    err.code = 'PIPEDRIVE_NOT_CONFIGURED';
    throw err;
  }
  if (!dealId && !personId) {
    const err = new Error('dealId or personId is required');
    err.statusCode = 400;
    err.code = 'PIPEDRIVE_MISSING_TARGET';
    throw err;
  }

  const token = process.env.PIPEDRIVE_API_TOKEN;
  const url = `${getBaseHost()}/v1/notes?api_token=${encodeURIComponent(token)}`;

  const body = { content };
  if (dealId != null) body.deal_id = Number(dealId);
  if (personId != null) body.person_id = Number(personId);

  let resp;
  try {
    resp = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    });
  } catch (netErr) {
    const err = new Error('pipedrive request failed');
    err.statusCode = 502;
    err.code = 'PIPEDRIVE_NETWORK_ERROR';
    err.cause = netErr;
    throw err;
  }

  let payload = null;
  try {
    payload = await resp.json();
  } catch (_) {
    payload = null;
  }

  if (!resp.ok || !payload || payload.success === false) {
    const err = new Error(
      (payload && payload.error) || `pipedrive returned ${resp.status}`
    );
    // 401/403 from Pipedrive -> bad token; surface as 502 (our config issue
    // upstream) but include the original status for debugging.
    err.statusCode = 502;
    err.code = 'PIPEDRIVE_API_ERROR';
    err.upstreamStatus = resp.status;
    throw err;
  }

  return payload.data;
}

/**
 * High-level helper: log a call (summary + objections) as a Pipedrive note.
 *
 * @param {object} params
 * @param {string} params.summary
 * @param {Array}  params.objections
 * @param {number|string} [params.dealId]
 * @param {number|string} [params.personId]
 * @returns {Promise<{noteId:number, target:object}>}
 */
async function logCall({ summary, objections, dealId, personId }) {
  const content = buildNoteContent({ summary, objections });
  const data = await createNote({ content, dealId, personId });
  return {
    noteId: data && data.id,
    target: { dealId: dealId || null, personId: personId || null }
  };
}

module.exports = {
  isConfigured,
  logCall,
  createNote,
  buildNoteContent,
  getBaseHost
};
