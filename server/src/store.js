// Storage behind one interface. MongoStore is the real database (set MONGODB_URI); FileStore keeps the same collections as JSON
// files so the server runs (and tests run) with no database installed. Collections:
//   questions   the question bank (seed questions + the Question Agent's), one document per question
//   screenings  one document per finished screening / weekly check-in  (the "longitudinal screening history")
//   responses   one document per answer, as sent by the app (telemetry)
//   agent_runs  one document per Question Agent run (what it was asked, what it added, what it rejected)
import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

export const COLLECTIONS = ['questions', 'screenings', 'responses', 'agent_runs'];

export class FileStore {
  constructor(dir) {
    this.kind = 'file';
    this.dir = dir;
    mkdirSync(dir, { recursive: true });
    this.cache = {};
  }
  _load(c) {
    if (!this.cache[c]) {
      const f = join(this.dir, `${c}.json`);
      this.cache[c] = existsSync(f) ? JSON.parse(readFileSync(f, 'utf8')) : [];
    }
    return this.cache[c];
  }
  _save(c) {
    writeFileSync(join(this.dir, `${c}.json`), JSON.stringify(this.cache[c], null, 1));
  }
  async init() {}
  async insertMany(c, docs) {
    const all = this._load(c);
    for (const d of docs) all.push({ _id: d._id ?? `${c}_${all.length + 1}_${Math.random().toString(36).slice(2, 8)}`, ...d });
    this._save(c);
    return docs.length;
  }
  async insertOne(c, doc) {
    await this.insertMany(c, [doc]);
    return doc;
  }
  async find(c, filter = {}, { sort, limit } = {}) {
    let r = this._load(c).filter((d) => Object.entries(filter).every(([k, v]) => (v && typeof v === 'object' && '$in' in v ? v.$in.includes(d[k]) : d[k] === v)));
    if (sort) {
      const [[k, dir]] = Object.entries(sort);
      r = [...r].sort((a, b) => (a[k] > b[k] ? 1 : a[k] < b[k] ? -1 : 0) * dir);
    }
    return limit ? r.slice(0, limit) : r;
  }
  async count(c, filter = {}) {
    return (await this.find(c, filter)).length;
  }
  async upsertQuestion(q) {
    const all = this._load('questions');
    const i = all.findIndex((d) => d.lang === q.lang && d.id === q.id);
    if (i >= 0) all[i] = { ...all[i], ...q };
    else all.push({ _id: `questions_${all.length + 1}`, ...q });
    this._save('questions');
  }
  async close() {}
}

export class MongoStore {
  constructor(uri, dbName) {
    this.kind = 'mongodb';
    this.uri = uri;
    this.dbName = dbName;
  }
  async init() {
    const { MongoClient } = await import('mongodb');
    this.client = new MongoClient(this.uri, { serverSelectionTimeoutMS: 8000 });
    await this.client.connect();
    this.db = this.client.db(this.dbName);
    await this.db.collection('questions').createIndex({ lang: 1, id: 1 }, { unique: true });
    await this.db.collection('questions').createIndex({ lang: 1, subtest: 1, difficulty: 1, status: 1 });
    await this.db.collection('screenings').createIndex({ student_id: 1, test_date: -1 });
    await this.db.collection('responses').createIndex({ student_id: 1, ts: -1 });
    await this.db.collection('agent_runs').createIndex({ ts: -1 });
  }
  async insertMany(c, docs) {
    if (!docs.length) return 0;
    const r = await this.db.collection(c).insertMany(docs, { ordered: false });
    return r.insertedCount;
  }
  async insertOne(c, doc) {
    await this.db.collection(c).insertOne(doc);
    return doc;
  }
  async find(c, filter = {}, { sort, limit } = {}) {
    let cur = this.db.collection(c).find(filter);
    if (sort) cur = cur.sort(sort);
    if (limit) cur = cur.limit(limit);
    return cur.toArray();
  }
  async count(c, filter = {}) {
    return this.db.collection(c).countDocuments(filter);
  }
  async upsertQuestion(q) {
    await this.db.collection('questions').updateOne({ lang: q.lang, id: q.id }, { $set: q }, { upsert: true });
  }
  async close() {
    await this.client?.close();
  }
}

export async function openStore(cfg) {
  const s = cfg.mongoUri ? new MongoStore(cfg.mongoUri, cfg.mongoDb) : new FileStore(cfg.dataDir);
  await s.init();
  return s;
}
