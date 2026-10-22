# ʻOhana Lens — Rokid RV101 agent

**Speak → a real ʻohana agent replies on the lens + spoken aloud.** Uses the same public door as the family websites (`myagentohana.com/api/chat`), proven end-to-end 22 Oct 2026.

## What it does
1. Open → `🌺 ʻOHANA LENS` — tap **SPEAK** (or press the touchpad confirm key).
2. Dictate — your words appear live. Tap **⏹ SEND** when done.
3. Lens shows *thinking…* (a hold note from the hub), then the **real agent's reply** in green — and speaks it via TTS. Replies take ~20–60s: that's a real agent working, not lag.
4. Tap **AGAIN** for the next question. Top-right **EN/中** flips the speech-recognition language (handy for judges asking in Mandarin).

## Install (Shaka's iPhone + MacBook, ~15 min)
1. MacBook Chrome → https://aiui-global.rokid.com/ → sign in (Rokid app account).
2. Create / 新建 → **Import from local folder** → pick this `ohana-lens/` folder.
   (If no import: Create with Coding → paste the prompt on https://myagentohana.com/ohana-bot/ar/ — the generator builds an equivalent agent.)
3. Open the agent → **Build & Review → Package AIX** → wait for **Synced**.
4. iPhone Rokid AI app → **Settings → Developer / 开发者 → Update glasses resource** (更新眼镜资源包) → wait for "downloaded successfully".
5. Glasses on → **"Hi Rokid, open Ohana"** → 🌺.

## Troubleshooting
- **"the ʻohana is out of range"** → wifi/BT tether down; retry. The hub is public HTTPS — venue wifi or phone hotspot both work.
- **Mic error** → grant RECORD_AUDIO when prompted; re-open the agent.
- **English comes out garbled** → you're in 中 mode; tap the top-right toggle.
- **Agent not on glasses** → redo step 4 with the phone app killed + reopened; check the AIX shows *Synced*.

## Stage notes (Demo Day)
- Hallway flex: *"these same agents answer me through my glasses — watch."* Ask something short ("what is the ʻohana bot?") and let the room wait the ~30s — narrate Beat 1 while it thinks.
- Not a stage dependency: the pitch + totem demo stand without it.
- Dev agent = no store review, no KYC. Publishing = post-hackathon.
