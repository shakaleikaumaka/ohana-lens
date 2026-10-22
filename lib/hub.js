// ʻOhana Lens — hub client.
// Talks to the PUBLIC ʻohana chat door (same one the websites use):
//   POST /send  {session, name, text}         -> {ok, seq}
//   GET  /poll?session=..&after=N[&wait=25]   -> {messages:[{role,text,seq}], typing, now}
// The fleet is ASYNC: a hold note lands instantly, a real agent reply
// follows in ~20-60s. We poll patiently and filter the hold note out.

const HUBS = [
  'https://myagentohana.com/api/chat',            // primary (CF edge, GFW-friendliest)
  'https://ohana-chat.shakaverse.workers.dev',    // direct worker origin (fallback)
];

const SESSION = 'ar-glasses-shaka';
const NAME = 'Shaka (AR glasses)';
const POLL_MS = 3000;
const GIVE_UP_MS = 3 * 60 * 1000;   // fleet replies in ~20-60s; 3 min patience cap
const HOLD_MARKERS = ['on the way', 'hang tight', 'hold on', 'one moment'];

function isHoldNote(text) {
  const t = String(text || '').toLowerCase();
  return HOLD_MARKERS.some((m) => t.includes(m));
}

function keyedError(key, message) {
  return Object.assign(new Error(message || key), { key });
}

async function postSend(text) {
  let lastError = null;
  for (const hub of HUBS) {
    try {
      const res = await fetch(hub + '/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ session: SESSION, name: NAME, text }),
      });
      const data = await res.json();
      if (data && data.ok && typeof data.seq === 'number') return { hub, seq: data.seq };
      lastError = keyedError('sendRejected', (data && (data.error || data.message)) || 'send rejected');
    } catch (error) { lastError = error; }
  }
  throw keyedError('sendFailed', (lastError && lastError.message) || 'network unreachable');
}

async function pollOnce(hub, afterSeq) {
  const res = await fetch(hub + '/poll?session=' + encodeURIComponent(SESSION) + '&after=' + afterSeq, { cache: 'no-store' });
  const data = await res.json();
  return (data && Array.isArray(data.messages)) ? data.messages : [];
}

// ask(text, {onHold}) -> reply string. Throws keyed errors on failure/timeout.
// isCancelled() lets the page abandon a stale run (new question / page hide).
export async function askOhana(text, { onHold, isCancelled } = {}) {
  const { hub, seq } = await postSend(text);
  if (isCancelled && isCancelled()) throw keyedError('cancelled');
  const deadline = Date.now() + GIVE_UP_MS;
  let holdShown = false;
  while (Date.now() < deadline) {
    if (isCancelled && isCancelled()) throw keyedError('cancelled');
    await new Promise((r) => setTimeout(r, POLL_MS));
    let messages;
    try { messages = await pollOnce(hub, seq); } catch (_) { continue; }  // transient poll errors: keep trying
    for (const m of messages) {
      if (!m || m.role === 'visitor') continue;
      const text2 = m.text || '';
      if (isHoldNote(text2)) {
        if (!holdShown) { holdShown = true; if (onHold) onHold(text2); }
        continue;
      }
      return text2;   // first real agent reply wins
    }
  }
  throw keyedError('timeout', 'the ʻohana is thinking longer than usual');
}
