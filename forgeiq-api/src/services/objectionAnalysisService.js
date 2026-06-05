// ForgeIQ Objection / "Blown-Past" Detection Service
// Post-call analysis powered by Claude (Anthropic API).
//
// Given a call transcript (optionally with speaker labels), identifies each
// objection the PROSPECT raised and whether the REP addressed it or blew past
// it. Returns structured JSON.
//
// Config: ANTHROPIC_API_KEY (process.env). If absent, callers should treat the
// service as "not configured" — see isConfigured().

const Anthropic = require('@anthropic-ai/sdk');

// Cost/quality balance for post-call analysis.
const MODEL = 'claude-sonnet-4-6';
const MAX_TOKENS = 3072;

let client = null;

/**
 * @returns {boolean} true if ANTHROPIC_API_KEY is present in env.
 */
function isConfigured() {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

/**
 * Lazily build (and memoise) the Anthropic client so a missing key at boot
 * never crashes the process — it only fails at call time with a 503.
 */
function getClient() {
  if (!isConfigured()) return null;
  if (!client) {
    client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  }
  return client;
}

const SYSTEM_PROMPT = `You are an expert B2B sales coach analysing a sales call transcript.

Your single job: find every OBJECTION the PROSPECT raised, and judge whether the SALES REP handled it or "blew past" it (moved on / ignored / changed the subject without resolving the concern).

Definitions:
- objection: any prospect concern, hesitation, doubt, or pushback — about price, timing, authority, need, competitor, trust, features, contract terms, etc. Include soft objections ("I'm not sure...", "we already have something").
- addressed: the rep gave a direct, relevant response that engaged the concern (even if imperfect).
- blewPast: the rep ignored it, talked over it, changed topic, or gave a non-answer. blewPast is the inverse of addressed; exactly one of them is true per objection.
- severity: "high" = likely deal-killer if unresolved; "med" = meaningful risk; "low" = minor/easily handled.
- suggestedResponse: one concrete sentence the rep SHOULD have said (or should say in follow-up) to handle this objection well.

If speaker labels are present, use them to attribute who spoke. If not, infer rep vs prospect from context (the rep sells/asks for the business; the prospect evaluates/pushes back).

Return ONLY valid JSON (no markdown, no commentary) matching exactly this shape:
{
  "objections": [
    {
      "text": "verbatim or close paraphrase of the prospect's objection",
      "raisedBy": "prospect",
      "addressed": true,
      "blewPast": false,
      "severity": "low|med|high",
      "suggestedResponse": "one concrete sentence"
    }
  ],
  "summary": "2-3 sentence overview of the call and how well objections were handled",
  "talkRatio": { "repPct": 0, "prospectPct": 0 }
}

Rules:
- objections must be an array (empty [] if none found).
- addressed and blewPast must be booleans and must be opposites.
- severity must be exactly one of: low, med, high.
- talkRatio is your best estimate of speaking share; repPct + prospectPct should total ~100. If you cannot estimate, set both to 0.
- Output JSON only.`;

/**
 * Analyse a transcript for objections / blown-past concerns.
 *
 * @param {string} transcript            Raw call transcript text.
 * @param {Array|string} [speakerLabels] Optional speaker label hints
 *                                        (e.g. ["rep","prospect"]) or a note.
 * @returns {Promise<object>} { objections, summary, talkRatio }
 * @throws {Error} with .statusCode for caller mapping.
 */
async function analyzeTranscript(transcript, speakerLabels) {
  const anthropic = getClient();
  if (!anthropic) {
    const err = new Error('analysis not configured');
    err.statusCode = 503;
    err.code = 'ANALYSIS_NOT_CONFIGURED';
    throw err;
  }

  let userContent = `Sales call transcript:\n\n${transcript}`;
  if (speakerLabels) {
    const labelStr = Array.isArray(speakerLabels)
      ? speakerLabels.join(', ')
      : String(speakerLabels);
    if (labelStr.trim()) {
      userContent =
        `Speaker labels / hints: ${labelStr}\n\n` + userContent;
    }
  }

  let message;
  try {
    message = await anthropic.messages.create({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: userContent }]
    });
  } catch (apiErr) {
    // Surface upstream Anthropic failures as 502 (bad gateway) so they are
    // distinguishable from validation (400) and config (503) issues.
    const err = new Error('objection analysis upstream error');
    err.statusCode = apiErr.status && apiErr.status >= 400 && apiErr.status < 500
      ? 502
      : 502;
    err.code = 'ANALYSIS_UPSTREAM_ERROR';
    err.cause = apiErr;
    throw err;
  }

  const rawText =
    Array.isArray(message.content) &&
    message.content[0] &&
    typeof message.content[0].text === 'string'
      ? message.content[0].text
      : '';

  const parsed = parseAnalysis(rawText);
  return normalize(parsed);
}

/**
 * Extract JSON from the model output (handles bare JSON or fenced code block).
 */
function parseAnalysis(text) {
  if (!text) {
    const err = new Error('empty analysis response');
    err.statusCode = 502;
    err.code = 'ANALYSIS_EMPTY';
    throw err;
  }
  let jsonStr = null;
  const fenced = text.match(/```(?:json)?\s*([\s\S]+?)\s*```/i);
  if (fenced) {
    jsonStr = fenced[1];
  } else {
    const firstBrace = text.indexOf('{');
    const lastBrace = text.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      jsonStr = text.slice(firstBrace, lastBrace + 1);
    }
  }
  if (!jsonStr) {
    const err = new Error('could not parse analysis response');
    err.statusCode = 502;
    err.code = 'ANALYSIS_PARSE_ERROR';
    throw err;
  }
  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    const err = new Error('invalid JSON in analysis response');
    err.statusCode = 502;
    err.code = 'ANALYSIS_PARSE_ERROR';
    err.cause = e;
    throw err;
  }
}

const VALID_SEVERITY = new Set(['low', 'med', 'high']);

/**
 * Coerce the parsed object into the guaranteed contract shape. Never trust the
 * model output blindly — clamp/validate every field.
 */
function normalize(parsed) {
  const objectionsIn = Array.isArray(parsed.objections) ? parsed.objections : [];
  const objections = objectionsIn.map((o) => {
    const addressed = Boolean(o && o.addressed);
    // blewPast is the strict inverse of addressed regardless of model output.
    const blewPast = !addressed;
    let severity = (o && typeof o.severity === 'string'
      ? o.severity.toLowerCase().trim()
      : 'med');
    if (severity === 'medium') severity = 'med';
    if (!VALID_SEVERITY.has(severity)) severity = 'med';
    return {
      text: o && o.text != null ? String(o.text) : '',
      raisedBy: o && o.raisedBy != null ? String(o.raisedBy) : 'prospect',
      addressed,
      blewPast,
      severity,
      suggestedResponse:
        o && o.suggestedResponse != null ? String(o.suggestedResponse) : ''
    };
  });

  const result = {
    objections,
    summary: typeof parsed.summary === 'string' ? parsed.summary : ''
  };

  if (parsed.talkRatio && typeof parsed.talkRatio === 'object') {
    const repPct = Number(parsed.talkRatio.repPct);
    const prospectPct = Number(parsed.talkRatio.prospectPct);
    result.talkRatio = {
      repPct: Number.isFinite(repPct) ? repPct : 0,
      prospectPct: Number.isFinite(prospectPct) ? prospectPct : 0
    };
  }

  return result;
}

module.exports = { analyzeTranscript, isConfigured, MODEL };
