// OpenAI Whisper speech-to-text for Readle. The app records the child's voice and sends it here; this server holds the OpenAI key
// (the app never does). Whisper returns the words AND when each word started and ended, which is what the app's VoxLexi analysis
// needs for speech onset, duration and pauses.

// Whisper sometimes "hears" a stock phrase in near-silence. These are dropped when it was not sure there was speech at all.
const PHANTOMS = /^(thank(s| you)( so much)?( for watching)?|bye\.?|you|okay\.?|\.+|subtitles? by .*|please subscribe.*)$/i;

/** 0.4 s of silence as a 16 kHz mono WAV: the cheapest possible "does Whisper work right now?" check. */
export function silentWav(seconds = 0.4) {
  const n = Math.round(16000 * seconds);
  const b = Buffer.alloc(44 + n * 2);
  b.write('RIFF', 0);
  b.writeUInt32LE(36 + n * 2, 4);
  b.write('WAVEfmt ', 8);
  b.writeUInt32LE(16, 16);
  b.writeUInt16LE(1, 20);
  b.writeUInt16LE(1, 22);
  b.writeUInt32LE(16000, 24);
  b.writeUInt32LE(32000, 28);
  b.writeUInt16LE(2, 32);
  b.writeUInt16LE(16, 34);
  b.write('data', 36);
  b.writeUInt32LE(n * 2, 40);
  return b;
}

export function createWhisper({ apiKey, fetchImpl = fetch, model = 'whisper-1' }) {
  return {
    model,
    enabled: !!apiKey,
    healthy: true, // flips to false when the last probe failed (no credits, bad key, OpenAI down); the app then uses the phone's recogniser
    error: '',
    /** Asks Whisper to transcribe a moment of silence. Run at start-up and every few minutes. */
    async probe() {
      if (!apiKey) return false;
      try {
        await this.transcribe({ audio: silentWav(), lang: 'en', _probe: true });
        this.healthy = true;
        this.error = '';
      } catch (e) {
        this.healthy = false;
        this.error = String(e.message ?? e).slice(0, 160);
      }
      return this.healthy;
    },
    /** audio: Buffer (wav/m4a/…); returns the normalised result the app expects. */
    async transcribe({ audio, mime = 'audio/wav', lang = 'en', prompt = '' }) {
      if (!apiKey) throw new Error('OPENAI_API_KEY is not set');
      if (!audio?.length) throw new Error('empty audio');
      const form = new FormData();
      form.append('file', new Blob([audio], { type: mime }), mime.includes('wav') ? 'speech.wav' : 'speech.m4a');
      form.append('model', model);
      form.append('response_format', 'verbose_json');
      form.append('timestamp_granularities[]', 'word');
      form.append('timestamp_granularities[]', 'segment');
      form.append('temperature', '0');
      if (lang) form.append('language', lang);
      if (prompt) form.append('prompt', prompt.slice(0, 400));
      const res = await fetchImpl('https://api.openai.com/v1/audio/transcriptions', { method: 'POST', headers: { Authorization: `Bearer ${apiKey}` }, body: form });
      const text = await res.text();
      if (!res.ok) throw new Error(`Whisper ${res.status}: ${text.slice(0, 200).replace(/sk-[A-Za-z0-9_-]+/g, '[key]')}`);
      return normalise(JSON.parse(text));
    },
  };
}

/** verbose_json → {text, words:[{word,start,end}], confidence 0..1, noSpeech 0..1, duration} */
export function normalise(j) {
  const segs = j.segments ?? [];
  const words = (j.words ?? []).map((w) => ({ word: String(w.word).trim(), start: +w.start, end: +w.end })).filter((w) => w.word);
  // confidence: how sure Whisper was of what it wrote (exp of the average log-probability), counted only where it heard speech
  let num = 0, den = 0, ns = 0;
  for (const s of segs) {
    const d = Math.max(0.05, (s.end ?? 0) - (s.start ?? 0));
    num += Math.exp(Math.min(0, s.avg_logprob ?? -1)) * d * (1 - (s.no_speech_prob ?? 0));
    den += d;
    ns += (s.no_speech_prob ?? 0) * d;
  }
  const confidence = den ? Math.max(0, Math.min(1, num / den)) : 0;
  const noSpeech = den ? ns / den : 1;
  let text = String(j.text ?? '').trim();
  if (noSpeech > 0.45 && PHANTOMS.test(text.replace(/[.!?\s]+$/g, ''))) text = '';
  if (noSpeech > 0.85) text = '';
  return { text, words: text ? words : [], confidence: text ? confidence : 0, noSpeech, duration: +(j.duration ?? 0), language: j.language ?? '' };
}
