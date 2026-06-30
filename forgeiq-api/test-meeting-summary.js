// Battery for the general meeting-summary parser (PRD-general-meeting-recorder.md R2 / AC1).
// Proves parseMeetingSummary NEVER throws and NEVER fabricates structure. Run: node test-meeting-summary.js
'use strict';
const router = require('./src/routes/ai.routes');
const parse = router.parseMeetingSummary;
let pass = 0, fail = 0; const fails = [];
const ok = (c, m) => { if (c) pass++; else { fail++; fails.push(m); } };
const shapeOk = (o) => o && typeof o.summary === 'string'
  && Array.isArray(o.key_points) && Array.isArray(o.action_items)
  && Array.isArray(o.decisions) && Array.isArray(o.next_steps);

// 1. clean JSON
let r = parse('{"summary":"We discussed Q3.","key_points":["budget","hiring"],"action_items":[{"text":"send deck","owner":"Kevin","due":"Friday"}],"decisions":["approved budget"],"next_steps":["schedule follow-up"]}');
ok(shapeOk(r), '1 shape'); ok(r.summary === 'We discussed Q3.', '1 summary'); ok(r.key_points.length === 2, '1 key_points'); ok(r.action_items[0].owner === 'Kevin', '1 action owner');

// 2. fenced JSON
r = parse('Here is the summary:\n```json\n{"summary":"Sync call.","key_points":["x"],"action_items":[],"decisions":[],"next_steps":["ship"]}\n```\nThanks');
ok(shapeOk(r) && r.summary === 'Sync call.' && r.next_steps[0] === 'ship', '2 fenced');

// 3. missing keys → defaults, never undefined
r = parse('{"summary":"Only a summary."}');
ok(shapeOk(r) && r.summary === 'Only a summary.' && r.key_points.length === 0 && r.decisions.length === 0, '3 missing keys default to []');

// 4. wrong types coerced (key_points as string, summary as number)
r = parse('{"summary":123,"key_points":"not an array","action_items":null}');
ok(shapeOk(r) && r.summary === '' && r.key_points.length === 0 && r.action_items.length === 0, '4 wrong types coerced');

// 5. garbage / no JSON → summary = text slice, arrays empty, no throw
r = parse('The model returned plain prose with no JSON at all here.');
ok(shapeOk(r) && r.key_points.length === 0 && r.summary.length > 0, '5 prose fallback');

// 6. null / undefined / empty
for (const v of [null, undefined, '', '   ']) { r = parse(v); ok(shapeOk(r), `6 empty(${JSON.stringify(v)}) shape`); }

// 7. malformed JSON (opens brace, invalid) → fallback, no throw
r = parse('{ this is : not, valid json ]');
ok(shapeOk(r), '7 malformed no-throw');

// 8. high-volume randomized fuzz — must NEVER throw, ALWAYS valid shape
let seed = 99;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
const frags = ['{', '}', '"summary"', ':', '[', ']', 'null', '123', '"a"', ',', '```json', '```', 'text', '\n'];
for (let i = 0; i < 3000; i++) {
  let s = '';
  const n = 1 + Math.floor(rnd() * 12);
  for (let j = 0; j < n; j++) s += frags[Math.floor(rnd() * frags.length)] + (rnd() > 0.6 ? ' ' : '');
  try { const o = parse(s); ok(shapeOk(o), `8 fuzz#${i} shape`); }
  catch (e) { ok(false, `8 fuzz#${i} THREW: ${e.message}`); }
}

console.log(`\nBATTERY: ${pass} passed, ${fail} failed`);
if (fail) { fails.slice(0, 15).forEach((f) => console.log('  - ' + f)); process.exit(1); }
console.log('ALL PASS ✅ — parser never throws, never fabricates, always returns the 5-key shape');
