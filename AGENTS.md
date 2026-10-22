# ʻOhana Lens

Voice bridge from Rokid glasses to the ʻohana agent fleet.

- Tap SPEAK (or Enter/GlobalHook) → dictate → tap SEND → the public ʻohana hub answers (~20–60s) → reply renders on the lens in green and is spoken via `speechSynthesis`.
- `lib/asr.js`: mic PCM 16k → `SpeechRecognitionSession` dictation mode (VAD off — deterministic in noisy venues). Language toggle EN/中 on the top bar.
- `lib/hub.js`: POST `https://myagentohana.com/api/chat/send` then patient `/poll` (hold-note filtered, 3 min cap, runId cancellation).
- Permissions: `RECORD_AUDIO` only. Network = plain HTTPS fetch (dev agents may call arbitrary domains).

Derived from yodaos-project/AIUI `samples/realtime-voice-intelligence` (asr.js adapted with a `lang` option).
