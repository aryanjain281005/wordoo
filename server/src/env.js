// Reads settings from the process environment and, if present, the repo's git-ignored .env file (never committed).
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

export function loadEnv() {
  const out = {};
  for (const f of [join(root, '.env'), join(root, 'server', '.env')]) {
    if (!existsSync(f)) continue;
    for (const line of readFileSync(f, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$/);
      if (m) out[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
  return { ...out, ...process.env };
}

export function config(env = loadEnv()) {
  return {
    port: Number(env.PORT ?? 8787),
    host: env.HOST ?? '0.0.0.0',
    mongoUri: env.MONGODB_URI || '',
    mongoDb: env.MONGODB_DB || 'readle',
    geminiKey: env.GEMINI_API_KEY || '',
    openaiKey: env.OPENAI_API_KEY || '',
    geminiModels: (env.GEMINI_MODELS || env.GEMINI_MODEL || 'gemini-flash-latest,gemini-flash-lite-latest').split(',').map((x) => x.trim()).filter(Boolean),
    agentEnabled: (env.AGENT_ENABLED ?? '1') !== '0',
    agentBatch: Number(env.AGENT_BATCH ?? 10),
    agentMinIntervalMs: Number(env.AGENT_MIN_INTERVAL_MS ?? 0),
    dataDir: env.DATA_DIR || join(root, 'server', 'data'),
    apiToken: env.API_TOKEN || '',
  };
}
