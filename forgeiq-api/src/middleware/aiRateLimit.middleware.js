// ForgeIQ — Guest AI Rate Limiter (cross-project gate, mirrors eng-directory)
//
// WHY: POST /api/v1/ai/call-summary, /api/v1/ai/script-adherence and
// /api/v1/calls/analyze each call the Anthropic Claude API and are currently
// reachable WITHOUT auth. Uncapped = uncapped paid Anthropic spend + DoS vector.
//
// WHAT: Conservative in-process per-IP limiter. Single Render instance, so a
// simple in-memory Map is sufficient — no redis / new infra. Sliding-ish window
// using fixed hour/day buckets keyed by IP.
//
// FAIL-OPEN: any internal error in the limiter calls next() so the AI endpoints
// never go dark from a limiter bug. The happy path is preserved exactly.
//
// Apply ONLY to AI/LLM endpoints — never to /health or other routes.

// --- Tunable constants (env-overridable) ---
const AI_GUEST_HOURLY_LIMIT = parseInt(process.env.AI_GUEST_HOURLY_LIMIT, 10) || 15;
const AI_GUEST_DAILY_LIMIT = parseInt(process.env.AI_GUEST_DAILY_LIMIT, 10) || 40;

const HOUR_MS = 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

// In-memory counters keyed by IP.
// { hourCount, hourReset, dayCount, dayReset }
const counters = new Map();

// Periodic sweep so the Map doesn't grow unbounded. unref() so it never holds
// the process open. Guard for environments without unref (defensive).
const SWEEP_MS = HOUR_MS;
const sweepTimer = setInterval(() => {
  try {
    const now = Date.now();
    for (const [ip, c] of counters) {
      // Drop entries whose day window has fully expired and aren't active.
      if (now >= c.dayReset && now >= c.hourReset) {
        counters.delete(ip);
      }
    }
  } catch (_) {
    // never let the sweep crash the process
  }
}, SWEEP_MS);
if (sweepTimer && typeof sweepTimer.unref === 'function') {
  sweepTimer.unref();
}

function aiRateLimit(req, res, next) {
  try {
    const now = Date.now();
    // req.ip requires trust proxy to be set (done in app.js) to be the real
    // client IP on Render. Fall back defensively if absent.
    const ip = req.ip || req.connection?.remoteAddress || 'unknown';

    let c = counters.get(ip);
    if (!c) {
      c = { hourCount: 0, hourReset: now + HOUR_MS, dayCount: 0, dayReset: now + DAY_MS };
      counters.set(ip, c);
    }

    // Reset expired windows.
    if (now >= c.hourReset) {
      c.hourCount = 0;
      c.hourReset = now + HOUR_MS;
    }
    if (now >= c.dayReset) {
      c.dayCount = 0;
      c.dayReset = now + DAY_MS;
    }

    const overHour = c.hourCount >= AI_GUEST_HOURLY_LIMIT;
    const overDay = c.dayCount >= AI_GUEST_DAILY_LIMIT;

    if (overHour || overDay) {
      const resetAt = overDay ? c.dayReset : c.hourReset;
      const retryAfterSec = Math.max(1, Math.ceil((resetAt - now) / 1000));
      res.set('Retry-After', String(retryAfterSec));
      const window = overDay ? 'daily' : 'hourly';
      const limit = overDay ? AI_GUEST_DAILY_LIMIT : AI_GUEST_HOURLY_LIMIT;
      return res.status(429).json({
        success: false,
        data: null,
        error: `AI request ${window} limit reached (${limit}). Please try again in about ${Math.ceil(retryAfterSec / 60)} minute(s).`
      });
    }

    // Count this request and proceed.
    c.hourCount += 1;
    c.dayCount += 1;
    return next();
  } catch (err) {
    // FAIL-OPEN: never block the endpoint because of a limiter bug.
    console.error('aiRateLimit error (failing open):', err && err.message);
    return next();
  }
}

module.exports = {
  aiRateLimit,
  AI_GUEST_HOURLY_LIMIT,
  AI_GUEST_DAILY_LIMIT,
  // exported for tests
  _counters: counters
};
