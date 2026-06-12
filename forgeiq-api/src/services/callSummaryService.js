// CallSummaryService — Session 10
// Sends a call transcript to the Claude API and returns the structured
// summary defined in CLAUDE.md (summary, blown past, commitments, score).

const ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages';
const CLAUDE_MODEL = 'claude-sonnet-4-20250514';

const SYSTEM_PROMPT = `You are ForgeIQ's sales call analyst. You receive a raw sales call transcript and return a structured analysis as JSON.

Respond with ONLY a valid JSON object — no markdown fences, no commentary — matching exactly this shape:
{
  "summary": "2-3 sentence executive summary of the call",
  "went_well": ["bullet 1", "bullet 2", "bullet 3"],
  "learning_points": ["what to improve", "what was missed"],
  "blown_past": [
    {
      "timestamp": "04:17",
      "prospect_said": "exact quote",
      "signal_type": "HIGH | MED | LOW",
      "signal_description": "what the signal means",
      "what_happened": "what the rep did instead",
      "suggested_response": "what to say next time"
    }
  ],
  "commitments": [
    { "owner": "Rep | Prospect", "text": "what was committed", "due": "today | specific date" }
  ],
  "next_step": "specific recommended action",
  "call_score": 7,
  "talk_time_rep_pct": 38,
  "talk_time_prospect_pct": 62
}

Rules:
- "blown_past" lists buying signals or pain points the prospect raised that the rep talked past. Use signal_type HIGH, MED, or LOW only.
- call_score is an integer 1-10 for overall call quality.
- talk_time percentages are integers estimated from the transcript and should sum to roughly 100.
- If the transcript has no timestamps, estimate the timestamp from position in the call.
- Arrays may be empty but must always be present.`;

async function generateCallSummary(transcript) {
  if (!process.env.ANTHROPIC_API_KEY) {
    const err = new Error('Anthropic API key not configured');
    err.statusCode = 500;
    throw err;
  }

  const response = await fetch(ANTHROPIC_API_URL, {
    method: 'POST',
    headers: {
      'x-api-key': process.env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: 4096,
      system: SYSTEM_PROMPT,
      messages: [
        {
          role: 'user',
          content: `Analyse this sales call transcript:\n\n${transcript}`
        }
      ]
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    console.error('Claude API error:', response.status, errorText);
    const err = new Error('Claude API error');
    err.statusCode = 502;
    throw err;
  }

  const result = await response.json();
  const text = result.content?.[0]?.text;
  if (!text) {
    const err = new Error('Claude API returned empty response');
    err.statusCode = 502;
    throw err;
  }

  let parsed;
  try {
    // Strip accidental markdown fences before parsing
    const cleaned = text.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
    parsed = JSON.parse(cleaned);
  } catch (parseErr) {
    console.error('Failed to parse Claude summary JSON');
    const err = new Error('Claude API returned malformed summary');
    err.statusCode = 502;
    throw err;
  }

  return normaliseSummary(parsed);
}

function normaliseSummary(raw) {
  return {
    summary: typeof raw.summary === 'string' ? raw.summary : '',
    went_well: Array.isArray(raw.went_well) ? raw.went_well : [],
    learning_points: Array.isArray(raw.learning_points) ? raw.learning_points : [],
    blown_past: Array.isArray(raw.blown_past) ? raw.blown_past : [],
    commitments: Array.isArray(raw.commitments) ? raw.commitments : [],
    next_step: typeof raw.next_step === 'string' ? raw.next_step : '',
    call_score: Number.isFinite(raw.call_score) ? Math.round(raw.call_score) : null,
    talk_time_rep_pct: Number.isFinite(raw.talk_time_rep_pct) ? Math.round(raw.talk_time_rep_pct) : null,
    talk_time_prospect_pct: Number.isFinite(raw.talk_time_prospect_pct) ? Math.round(raw.talk_time_prospect_pct) : null
  };
}

// Re-engagement rule: score < 5 OR 2+ HIGH blown past signals
function isReEngagementCandidate(summary) {
  const highSignals = summary.blown_past.filter(
    (item) => String(item.signal_type).toUpperCase() === 'HIGH'
  ).length;
  return (summary.call_score !== null && summary.call_score < 5) || highSignals >= 2;
}

module.exports = { generateCallSummary, isReEngagementCandidate };
