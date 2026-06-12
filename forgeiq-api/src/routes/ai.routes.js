// ForgeIQ AI Routes
// Session 12 — AI Call Summary with Product Spec Accuracy Detection
// Powered by Claude API

const express = require('express');
const router = express.Router();
const Anthropic = require('@anthropic-ai/sdk');
const { aiRateLimit } = require('../middleware/aiRateLimit.middleware');

// Graceful degradation (Gate 3 support): never construct the client at module
// load and never call Anthropic without a key. Missing ANTHROPIC_API_KEY ->
// clean 503 JSON ("analysis not configured"), same pattern as calls.routes.js.
let anthropicClient = null;

function isConfigured() {
  return Boolean(process.env.ANTHROPIC_API_KEY);
}

function getAnthropicClient() {
  if (!anthropicClient) {
    anthropicClient = new Anthropic({
      apiKey: process.env.ANTHROPIC_API_KEY
    });
  }
  return anthropicClient;
}

// Guest AI rate limiter — gates every LLM endpoint in this router (these call
// the paid Anthropic API and are currently reachable without auth).
router.use(aiRateLimit);

// POST /api/v1/ai/call-summary
// Generate call summary with optional product spec accuracy analysis
router.post('/call-summary', async (req, res, next) => {
  try {
    const { transcript, product_specs } = req.body;

    if (!transcript) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'transcript is required'
      });
    }

    // --- config gate (graceful degradation when ANTHROPIC_API_KEY missing) ---
    if (!isConfigured()) {
      return res.status(503).json({
        success: false,
        data: null,
        error: 'analysis not configured'
      });
    }

    // Build prompt with optional product specs section
    let systemPrompt = `You are an expert sales call analyzer. Analyze the call transcript and return:
1. Executive summary (2-3 sentences)
2. What went well (3-5 bullets)
3. Learning points / missed opportunities (3-5 bullets)
4. Next steps (specific action)
5. Call quality score (1-10)
6. Talk time % for rep vs prospect`;

    if (product_specs && Object.keys(product_specs).length > 0) {
      systemPrompt += `\n\n7. PRODUCT SPEC ACCURACY:
- Did the rep correctly state the product specs when asked?
- Which specs were asked about? Which were correctly answered?
- Any spec questions left unanswered or answered incorrectly?
- Overall spec accuracy % (0-100)

Product specs provided to rep BEFORE call:
${JSON.stringify(product_specs, null, 2)}`;
    }

    const message = await getAnthropicClient().messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 2048,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: `Analyze this sales call transcript:\n\n${transcript}`
        }
      ]
    });

    const analysisText = message.content[0].text;

    // Parse Claude's response into structured format
    // (Simple regex extraction — can enhance with better parsing)
    const summary = {
      raw_analysis: analysisText,
      call_score: extractScore(analysisText),
      talk_time_rep_pct: extractTalkTime(analysisText, 'rep'),
      talk_time_prospect_pct: extractTalkTime(analysisText, 'prospect')
    };

    if (product_specs) {
      summary.spec_accuracy_pct = extractSpecAccuracy(analysisText);
      summary.questions_asked = extractSpecQuestions(analysisText);
      summary.correctly_answered = extractCorrectAnswers(analysisText);
      summary.missed_opportunities = extractMissedSpec(analysisText);
    }

    res.json({
      success: true,
      data: summary,
      error: null
    });
  } catch (error) {
    console.error('AI call-summary error:', error);
    next(error);
  }
});

// Helper functions to extract structured data from Claude's text response
function extractScore(text) {
  // Broadened to tolerate Claude markdown: "**Call Quality Score:** 7/10",
  // "Score: 7 out of 10", "Quality Score - 7". Strictly additive — still
  // returns null when nothing matches (same fail-safe as before).
  const patterns = [
    /(?:call\s*quality\s*score|quality\s*score|call\s*score|score)\s*[:\-]?\s*\**\s*(\d{1,2})\s*(?:\/\s*10|out\s*of\s*10)/i,
    /(?:call\s*quality\s*score|quality\s*score|call\s*score|score)\s*[:\-]?\s*\**\s*(\d{1,2})\b/i,
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) {
      const n = parseInt(m[1], 10);
      if (n >= 0 && n <= 10) return n;
    }
  }
  return null;
}

function extractTalkTime(text, speaker) {
  // Tolerate markdown/punctuation between the speaker word and the percentage,
  // e.g. "Rep talk time: **38%**", "Prospect - 62 %". Additive broadening;
  // null fail-safe preserved.
  const patterns = [
    new RegExp(`${speaker}[^\\d%]{0,40}?(\\d{1,3})\\s*%`, 'i'),
    new RegExp(`(\\d{1,3})\\s*%[^\\d]{0,20}?${speaker}`, 'i'),
  ];
  for (const p of patterns) {
    const m = text.match(p);
    if (m) {
      const n = parseInt(m[1], 10);
      if (n >= 0 && n <= 100) return n;
    }
  }
  return null;
}

function extractSpecAccuracy(text) {
  const match = text.match(/spec accuracy[:\s]+(\d+)%/i);
  return match ? parseInt(match[1], 10) : null;
}

function extractSpecQuestions(text) {
  // Extract bullet points from "specs asked about" section
  const section = text.match(/specs? (?:asked|questions)[^\n]*\n((?:[-•*]\s+[^\n]+\n?)+)/i);
  if (!section) return [];
  return section[1].split('\n').filter(l => l.trim()).map(l => l.replace(/^[-•*]\s+/, '').trim());
}

function extractCorrectAnswers(text) {
  const section = text.match(/correctly answered[^\n]*\n((?:[-•*]\s+[^\n]+\n?)+)/i);
  if (!section) return [];
  return section[1].split('\n').filter(l => l.trim()).map(l => l.replace(/^[-•*]\s+/, '').trim());
}

function extractMissedSpec(text) {
  const section = text.match(/(?:unanswered|missed|incorrect)[^\n]*\n((?:[-•*]\s+[^\n]+\n?)+)/i);
  if (!section) return [];
  return section[1].split('\n').filter(l => l.trim()).map(l => l.replace(/^[-•*]\s+/, '').trim());
}



// POST /api/v1/ai/script-adherence
// Analyze script adherence for sales calls
router.post('/script-adherence', async (req, res, next) => {
  try {
    const { transcript, talking_points } = req.body;

    if (!transcript || !Array.isArray(talking_points)) {
      return res.status(400).json({
        success: false,
        data: null,
        error: 'transcript and talking_points (array) are required'
      });
    }

    // --- config gate (graceful degradation when ANTHROPIC_API_KEY missing) ---
    if (!isConfigured()) {
      return res.status(503).json({
        success: false,
        data: null,
        error: 'analysis not configured'
      });
    }

    const systemPrompt = `You are analyzing a sales call transcript for adherence to a pre-defined script.

Script talking points:
${talking_points.map((p, i) => `${i + 1}. ${p}`).join('\n')}

Return JSON with:
- adherence_pct: overall percentage (0-100) of talking points covered
- covered: array of talking point indices (1-based) that were mentioned
- skipped: array of talking point indices (1-based) that were NOT mentioned
- variance_notes: brief explanation of major deviations or strong adherence`;

    const message = await getAnthropicClient().messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 1024,
      system: systemPrompt,
      messages: [
        {
          role: 'user',
          content: `Analyze this transcript for script adherence:\n\n${transcript}`
        }
      ]
    });

    const analysisText = message.content[0].text;

    // Extract JSON from Claude's response (handles both raw JSON and markdown code blocks)
    let adherenceData;
    try {
      const jsonMatch = analysisText.match(/```json\n([\s\S]+?)\n```/) ||
                        analysisText.match(/\{[\s\S]+\}/);
      adherenceData = jsonMatch ? JSON.parse(jsonMatch[1] || jsonMatch[0]) : {
        adherence_pct: 0,
        covered: [],
        skipped: talking_points.map((_, i) => i + 1),
        variance_notes: 'Failed to parse adherence analysis'
      };
    } catch (parseError) {
      // Fallback: extract percentage manually
      const pctMatch = analysisText.match(/(\d+)%/);
      adherenceData = {
        adherence_pct: pctMatch ? parseInt(pctMatch[1], 10) : 0,
        covered: [],
        skipped: talking_points.map((_, i) => i + 1),
        variance_notes: analysisText
      };
    }

    res.json({
      success: true,
      data: adherenceData,
      error: null
    });
  } catch (error) {
    console.error('AI script-adherence error:', error);
    next(error);
  }
});

module.exports = router;
