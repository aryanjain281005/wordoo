// Thin Gemini client: one structured-JSON call. The API key comes from the server's environment, never from the app.
// Models are tried in order: if the first one is slow (default 20 s) or fails, the next one answers, so one congested model
// cannot stall the Question Agent.
export function geminiClient({ apiKey, models, model, fetchImpl = fetch, firstTimeoutMs = 20000, lastTimeoutMs = 60000 }) {
  const list = (models && models.length ? models : [model || 'gemini-flash-latest']).filter(Boolean);
  const client = {
    model: list[0],
    lastModel: list[0],
    async generateJson(prompt, schema) {
      if (!apiKey) throw new Error('GEMINI_API_KEY is not set');
      let lastErr;
      for (let i = 0; i < list.length; i++) {
        const m = list[i];
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${m}:generateContent`;
        const generationConfig = { responseMimeType: 'application/json', responseSchema: schema, temperature: 0.9 };
        // no hidden "thinking" on the full models: much faster, and the checks in subtests.js verify the result (lite models have none)
        if (!/lite/.test(m)) generationConfig.thinkingConfig = { thinkingBudget: 0 };
        const ctl = new AbortController();
        const t = setTimeout(() => ctl.abort(), i === list.length - 1 ? lastTimeoutMs : firstTimeoutMs);
        try {
          const res = await fetchImpl(url, { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-goog-api-key': apiKey }, body: JSON.stringify({ contents: [{ role: 'user', parts: [{ text: prompt }] }], generationConfig }), signal: ctl.signal });
          const text = await res.text();
          if (!res.ok) throw new Error(`Gemini ${m} ${res.status}: ${text.slice(0, 200).replace(/AQ\.[A-Za-z0-9_-]+/g, '[key]')}`);
          const data = JSON.parse(text);
          const out = (data?.candidates?.[0]?.content?.parts ?? []).map((p) => p.text ?? '').join('');
          if (!out) throw new Error(`Gemini ${m} returned no text (${data?.candidates?.[0]?.finishReason ?? 'no candidate'})`);
          const json = JSON.parse(out);
          client.lastModel = m;
          return json;
        } catch (e) {
          lastErr = e.name === 'AbortError' ? new Error(`Gemini ${m} timed out`) : e;
        } finally {
          clearTimeout(t);
        }
      }
      throw lastErr;
    },
  };
  return client;
}
