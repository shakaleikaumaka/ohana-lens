<script def>
{
  "navigationBarTitleText": "ʻOhana Lens"
}
</script>

<script setup>
import { createRecognizer, collectTranscript } from '../../lib/asr.js';
import { askOhana } from '../../lib/hub.js';

// Tap-to-talk state machine:
//   idle -> listening -> thinking -> reply -> idle
//                                     -> error -> (retry)
// Enter / GlobalHook (glasses touchpad confirm) = the primary action.
// A type row is always available (stage-noise proof + simulator testing).
export default {
  data: {
    status: 'idle',        // idle | listening | thinking | reply | error
    question: '',
    liveText: '',          // interim transcript while listening
    answer: '',
    hint: 'tap SPEAK and ask the ʻohana',
    lang: 'en-US',         // ASR language; tap 中/EN to flip
    btn: '🎤 SPEAK',
    typed: '',
    // precomputed render strings (no wx:if / expression bindings in this runtime)
    qLine: '',
    liveLine: '',
    langLabel: 'EN',
    btnClass: 'primary',
  },

  onLoad() {
    this.runId = 0;         // cancels stale polls
    this.recognizer = null;
    this.lastTranscript = '';
  },

  onUnload() { this.teardown(); },
  onHide() { this.teardown(); },

  ui(patch) {
    const p = patch || {};
    const status = p.status !== undefined ? p.status : this.data.status;
    const question = p.question !== undefined ? p.question : this.data.question;
    const liveText = p.liveText !== undefined ? p.liveText : this.data.liveText;
    p.status = status;
    // precomputed render strings — this runtime does not apply wx:if in
    // single-file pages, so empty strings are the conditional (invisible on black)
    p.qLine = question ? ('YOU: ' + question) : '';
    p.liveLine = status === 'listening' ? (liveText || '…') : '';
    p.btnClass = status === 'listening' ? 'primary hot' : 'primary';
    this.setData(p);
  },

  teardown() {
    this.runId += 1;
    if (this.recognizer) { try { this.recognizer.abort(); } catch (_) {} this.recognizer = null; }
  },

  // ---- voice ----
  startListening() {
    this.teardownRecognizersOnly();
    const rec = createRecognizer({
      SpeechRecognitionSession: typeof SpeechRecognitionSession === 'undefined' ? null : SpeechRecognitionSession,
      captureMode: 'wearer',
      vad: false,                 // dictation: tap to start, tap to send (venue-noise proof)
      lang: this.data.lang,
    });
    this.recognizer = rec;
    this.lastTranscript = '';
    rec.onresult = (event) => {
      const t = collectTranscript(event);
      if (t) { this.lastTranscript = t; this.setData({ liveText: t }); }
    };
    rec.onerror = (payload = {}) => {
      this.ui({ status: 'error', btn: '↻ RETRY', hint: 'mic/ASR: ' + (payload.message || payload.key || 'failed'), liveText: '' });
    };
    rec.onend = () => {
      this.recognizer = null;
      const t = (this.lastTranscript || '').trim();
      if (this.data.status !== 'listening') return;          // aborted on purpose
      if (!t) { this.ui({ status: 'idle', btn: '🎤 SPEAK', hint: 'heard nothing — tap and speak right after the dot', liveText: '' }); return; }
      this.sendToOhana(t);
    };
    rec.onstart = () => {};
    rec.start();
    this.ui({ status: 'listening', btn: '⏹ SEND', liveText: '', answer: '', hint: 'listening… tap SEND when done' });
  },

  teardownRecognizersOnly() {
    if (this.recognizer) { try { this.recognizer.abort(); } catch (_) {} this.recognizer = null; }
  },

  stopListening() {
    if (this.recognizer) this.recognizer.stop();   // close flushes final result → onend → send
  },

  // ---- brain ----
  async sendToOhana(text) {
    const t = String(text || '').trim();
    if (!t) return;
    const myRun = ++this.runId;
    this.ui({ status: 'thinking', question: t, liveText: '', answer: '', btn: '⏳', hint: 'thinking… a real agent is answering (20–60s)' });
    try {
      const reply = await askOhana(t, {
        isCancelled: () => myRun !== this.runId,
        onHold: (note) => { if (myRun === this.runId) this.setData({ hint: note }); },
      });
      if (myRun !== this.runId) return;
      this.ui({ status: 'reply', answer: reply, btn: '🎤 AGAIN', hint: 'tap AGAIN for the next question' });
      this.speak(reply);
    } catch (error) {
      if (myRun !== this.runId) return;
      const msg = (error && error.key === 'timeout')
        ? 'the ʻohana is still thinking — tap RETRY to check again'
        : 'the ʻohana is out of range — check the wifi, tap RETRY';
      this.ui({ status: 'error', btn: '↻ RETRY', hint: msg });
    }
  },

  speak(text) {
    try {
      if (typeof speechSynthesis === 'undefined' || typeof SpeechSynthesisUtterance === 'undefined') return;
      speechSynthesis.speak(new SpeechSynthesisUtterance(String(text).slice(0, 800)), 'immediate');
    } catch (_) {}
  },

  // ---- input ----
  primary() {
    if (this.data.status === 'listening') { this.stopListening(); return; }
    if (this.data.status === 'thinking') return;              // let it land
    if (this.data.status === 'error' && this.data.question) { this.sendToOhana(this.data.question); return; }
    this.startListening();
  },

  onTyped(event) {
    this.setData({ typed: event.detail.value });
  },

  sendTyped() {
    const t = (this.data.typed || '').trim();
    if (!t) return;
    this.setData({ typed: '' });
    this.sendToOhana(t);
  },

  toggleLang() {
    const next = this.data.lang === 'en-US' ? 'zh-CN' : 'en-US';
    this.setData({ lang: next, langLabel: next === 'en-US' ? 'EN' : '中' });
  },

  onKeyUp(event) {
    if (event && (event.code === 'Enter' || event.code === 'GlobalHook')) this.primary();
  },
}
</script>

<page>
  <view class="root">
    <view class="top">
      <text class="title">🌺 ʻOHANA LENS</text>
      <button class="langbtn" bindtap="toggleLang">{{ langLabel }}</button>
    </view>

    <scroll-view class="body" scroll-y>
      <text class="q">{{ qLine }}</text>
      <text class="live">{{ liveLine }}</text>
      <text class="a">{{ answer }}</text>
      <text class="hint">{{ hint }}</text>
    </scroll-view>

    <view class="bottom">
      <input class="typebox" value="{{ typed }}" placeholder="or type here…" bindinput="onTyped" />
      <button class="sendbtn" bindtap="sendTyped">➤</button>
      <button class="{{ btnClass }}" bindtap="primary">{{ btn }}</button>
    </view>
  </view>
</page>

<style>
.root { display: flex; flex-direction: column; height: 100vh; background: #000000; padding: 10px 12px; box-sizing: border-box; }
.top { display: flex; flex-direction: row; align-items: center; justify-content: space-between; }
.title { color: #40ff5e; font-size: 20px; font-weight: 600; }
.langbtn { color: rgba(64,255,94,0.72); border: 1px solid rgba(64,255,94,0.48); border-radius: 10px; padding: 2px 10px; font-size: 16px; text-align: center; }
.body { flex: 1; margin: 10px 0; border: 1px solid rgba(64,255,94,0.24); border-radius: 10px; padding: 10px; box-sizing: border-box; }
.q { color: rgba(64,255,94,0.48); font-size: 16px; line-height: 22px; display: block; margin-bottom: 6px; }
.live { color: #40ff5e; font-size: 20px; line-height: 26px; display: block; }
.a { color: rgba(64,255,94,0.72); font-size: 19px; line-height: 26px; display: block; }
.hint { color: rgba(64,255,94,0.48); font-size: 14px; line-height: 20px; display: block; margin-top: 8px; }
.bottom { display: flex; flex-direction: row; align-items: center; justify-content: center; }
.typebox { flex: 1; color: #40ff5e; border: 1px solid rgba(64,255,94,0.24); border-radius: 12px; padding: 6px 10px; font-size: 16px; margin-right: 8px; background: rgba(64,255,94,0.06); }
.sendbtn { color: #40ff5e; border: 1px solid rgba(64,255,94,0.48); border-radius: 12px; padding: 6px 12px; font-size: 18px; margin-right: 8px; text-align: center; }
.primary { color: #40ff5e; border: 2px solid rgba(64,255,94,0.72); border-radius: 14px; padding: 8px 20px; font-size: 20px; font-weight: 700; text-align: center; }
.primary.hot { color: #000000; background: #40ff5e; }
</style>
