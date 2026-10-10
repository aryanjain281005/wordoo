# Speech recognition: OpenAI Whisper (with the phone's recogniser as backup)

`lib/screening/speech_engine.dart` is the one place the screening listens to the child.

```
child taps the mic
  │  SpeechEngine.capture(...)
  ├─ Whisper ready?  (Cloud.whisperAvailable → GET /health → "whisper": true, re-checked every 90 s)
  │     yes → record the microphone (16 kHz mono WAV, `record` package)
  │           stop on silence after speech (pauseFor) or at the time limit; if nothing was said nothing is uploaded
  │           POST /transcribe (server/src/whisper.js) → OpenAI whisper-1, verbose_json, word timestamps, temperature 0
  │           WhisperMapper → VoxLexi.analyzeWords → SpeechMetrics
  │               onset  = first word start      (latencyMs)
  │               length = first start → last end (durationMs)
  │               pauses = gaps between words ≥ 300 ms (pauses, pauseMs)
  │               confidence = exp(avg log-prob) of the segments, weighted by speech
  └─ no (offline / no key / no credits / a failed request: Whisper is skipped for 2 min)
        → the phone's own speech_to_text, exactly as before
→ SpeechMetrics → VoxLexi.bestMatch / scoreFromMatch → ItemResponse → Scorer (unchanged) and the adaptive screening (unchanged)
```

* The OpenAI key lives only in the server's `.env` (`OPENAI_API_KEY`). The app sends audio to the Readle server, never to OpenAI.
* The hint sent with each recording describes the kind of speech ("a young child reads one made-up word aloud"), never the expected
  answer, so Whisper does not "correct" a mispronunciation towards the target.
* Whisper sometimes writes a stock phrase ("Thank you.") for near-silence; the server drops it when it was not sure there was speech.
* The server checks Whisper itself (a silent clip, at start-up and every 10 minutes). If OpenAI says the account has no credits or
  the key is wrong, `/health` shows `"whisper": false, "whisperError": "…"` and the app keeps using the phone's recogniser,
  so no child's answer is lost. **Status on 10 Oct: the OpenAI account reports "no credits remaining" → add credits at
  platform.openai.com/settings/organization/billing, then it switches on by itself within 10 minutes.**
* Cost: whisper-1 is billed per audio minute (about $0.006), and only the seconds of speech are uploaded.
