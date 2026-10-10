// Thin Gemini client: one structured-JSON call. The API key comes from the server's environment, never from the app.
export function geminiClient({ apiKey, model, fetchImpl = fetch }) {
  return {
    model,
    async generateJson(prompt, schema, { timeoutMs = 60000 } = {}) {
      if (!apiKey) throw new Error('GEMINI_API_KEY is not set');
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
      const body = {
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: 'application/json', responseSchema: schema, temperature: 0.9, thinkingConfig: { thinkingBudget: 0 } }, // no hidden "thinking": much faster, and the checks in subtests.js verify the result
      };
      const ctl = new AbortController();
      const t = setTimeout(() => ctl.abort(), timeoutMs);
      try {
        const res = await fetchImpl(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-goog-api-key': apiKey }, body: JSON.stringify(body), signal: ctl.signal });
        const text = await res.text();
        if (!res.ok) throw new Error(`Gemini ${res.status}: ${text.slice(0, 200).replace(/AQ\.[A-Za-z0-9_-]+/g, '[key]')}`);
        const data = JSON.parse(text);
        const parts = data?.candidates?.[0]?.content?.parts ?? [];
        const out = parts.map((p) => p.text ?? '').join('');
        if (!out) throw new Error(`Gemini returned no text (${data?.candidates?.[0]?.finishReason ?? 'no candidate'})`);
        return JSON.parse(out);
      } finally {
        clearTimeout(t);
      }
    },
  };
}
