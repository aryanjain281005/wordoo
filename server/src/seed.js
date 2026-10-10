// Puts the questions that ship with the app (exported by `dart run tool/export_bank.dart`) into the database,
// so the database — not the app code — is the question bank. Safe to run again: existing questions are left alone.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

export async function seedBank(store, file = join(dirname(fileURLToPath(import.meta.url)), '..', 'seed', 'questions_en.json')) {
  if (!existsSync(file)) return 0;
  const seed = JSON.parse(readFileSync(file, 'utf8'));
  const have = new Set((await store.find('questions', { lang: seed.lang })).map((q) => q.id));
  let n = 0;
  for (const q of seed.questions) {
    if (have.has(q.id)) continue;
    await store.upsertQuestion({ ...q, lang: seed.lang, source: 'seed', status: 'active', createdAt: seed.exportedAt });
    n++;
  }
  return n;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const { config } = await import('./env.js');
  const { openStore } = await import('./store.js');
  const store = await openStore(config());
  console.log(`seeded ${await seedBank(store)} questions into ${store.kind}`);
  await store.close();
}
