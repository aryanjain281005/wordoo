// What the Question Agent can write, per screening station ("subtest"), and how each generated question is checked and
// turned into the same JSON the app's SItem uses (lib/screening/models.dart). Nothing from Gemini goes into the bank unchecked.

export const TIERS = { easy: 1, medium: 2, hard: 3 };
export const TIER_NAMES = ['', 'easy', 'medium', 'hard'];

const WORD = /^[a-z]+$/;
const isWord = (w) => typeof w === 'string' && WORD.test(w);
const clean = (s) => String(s ?? '').trim();
const lower = (s) => clean(s).toLowerCase();
const pic = (label, emoji) => ({ label: lower(label), emoji: clean(emoji), say: lower(label) });
const hasEmoji = (e) => typeof e === 'string' && e.trim().length > 0 && !/[a-z0-9]/i.test(e.trim());
const ending = (w, n = 2) => w.slice(-n);

// ---- Gemini response schemas (OpenAPI subset) -------------------------------------------------------------------------
const S = (props, required) => ({ type: 'OBJECT', properties: props, required: required ?? Object.keys(props) });
const str = { type: 'STRING' };
const arr = (items) => ({ type: 'ARRAY', items });
const opt = S({ label: str, emoji: str });

// An item of every kind is described by one of these builders: it receives Gemini's raw object and returns
// { item } (the SItem fields) or { reject: 'why' }.
export const SUBTESTS = {
  rhyme: {
    describe: 'Rhyme recognition. The child sees a picture word and hears "Which one rhymes with <word>?" and chooses from 3 pictures.',
    rules: 'Use common one-syllable nouns a 5-8 year old knows, each with ONE clear emoji. "correct" must truly rhyme with "word" (same ending sound). The two "wrong" words must NOT rhyme with it. easy = very familiar CVC words (cat/hat); medium = digraph or long-vowel endings (ring/king, cake/snake); hard = harder endings or look-alike distractors (star/car, goat/boat).',
    schema: S({ word: str, emoji: str, correct: opt, wrong: arr(opt) }),
    build(g, tier, ctx) {
      const word = lower(g.word), c = g.correct, w = g.wrong ?? [];
      if (!isWord(word) || !hasEmoji(g.emoji)) return { reject: 'bad target word/emoji' };
      if (w.length !== 2 || !c) return { reject: 'needs 1 correct + 2 wrong' };
      const labels = [lower(c.label), lower(w[0].label), lower(w[1].label)];
      if (labels.some((l) => !isWord(l)) || new Set([...labels, word]).size !== 4) return { reject: 'duplicate or non-word options' };
      if (![c, ...w].every((o) => hasEmoji(o.emoji))) return { reject: 'option without emoji' };
      if (ending(labels[0]) !== ending(word)) return { reject: 'correct option does not share the ending' };
      if (labels.slice(1).some((l) => ending(l) === ending(word))) return { reject: 'a wrong option rhymes too' };
      return { item: { target: word, emoji: clean(g.emoji), say: `Which one rhymes with ${word}?`, options: [pic(c.label, c.emoji), pic(w[0].label, w[0].emoji), pic(w[1].label, w[1].emoji)] }, key: `${word}|${labels[0]}` };
    },
  },
  firstSound: {
    describe: 'Initial sound. The child hears "Which one starts with <sound>?" and chooses from 3 pictures.',
    rules: '"letter" is one consonant letter; "sound" is how to say it as a short sound (m = "mmm", b = "buh", s = "sss"). The correct picture word must START with that letter; both wrong words must start with different letters. Common nouns with one clear emoji.',
    schema: S({ letter: str, sound: str, correct: opt, wrong: arr(opt) }),
    build(g) {
      const letter = lower(g.letter);
      if (!/^[bcdfghjklmnpqrstvwxyz]$/.test(letter)) return { reject: 'letter must be one consonant' };
      const c = g.correct, w = g.wrong ?? [];
      if (!c || w.length !== 2) return { reject: 'needs 1 correct + 2 wrong' };
      const labels = [lower(c.label), lower(w[0].label), lower(w[1].label)];
      if (labels.some((l) => !isWord(l)) || new Set(labels).size !== 3) return { reject: 'bad options' };
      if (labels[0][0] !== letter) return { reject: 'correct option does not start with the letter' };
      if (labels.slice(1).some((l) => l[0] === letter)) return { reject: 'a wrong option starts with the letter' };
      const sound = lower(g.sound);
      if (!/^[a-z]{2,4}$/.test(sound) || sound[0] !== letter) return { reject: 'sound must begin with the letter' };
      return { item: { target: letter, say: `Which one starts with ${sound}?`, options: [pic(c.label, c.emoji), pic(w[0].label, w[0].emoji), pic(w[1].label, w[1].emoji)] }, key: `${letter}|${labels[0]}` };
    },
  },
  phonemeManip: {
    describe: 'Sound deletion / replacement. The child hears "Say <word>, but take away the <x> sound." or "Say <word>. Now change <a> to <b>." and chooses the answer from 3 spoken options.',
    rules: 'Use ONLY these two operations: "delete_first" (remove the first sound; word must start with a consonant letter and the rest must be a pronounceable chunk, e.g. cat -> at) or "replace_first" (change the first letter; the new word must be a real word, e.g. bat -> hat). "answer" must equal what the operation produces. Give two wrong options that are plausible slips. easy = 3-letter words; medium = 4 letters; hard = consonant blends (stop -> sop is NOT allowed; use delete_first on the first letter only).',
    schema: S({ word: str, op: str, removed: str, replaceWith: str, answer: str, wrong: arr(str) }, ['word', 'op', 'answer', 'wrong']),
    build(g) {
      const word = lower(g.word), answer = lower(g.answer), op = lower(g.op);
      if (!isWord(word) || !isWord(answer)) return { reject: 'non-letter word' };
      let say;
      if (op === 'delete_first') {
        if (answer !== word.slice(1) || word.length < 3) return { reject: 'answer is not the word without its first letter' };
        const sound = lower(g.removed) || word[0];
        const same = sound === word[0] || (word[0] === 'c' && sound === 'k') || (word[0] === 'k' && sound === 'c');
        if (!/^[a-z]$/.test(sound) || !same) return { reject: 'removed sound must be the first sound of the word' };
        say = `Say ${word}, but take away the ${sound} sound.`;
      } else if (op === 'replace_first') {
        const nw = lower(g.replaceWith);
        if (!/^[a-z]$/.test(nw) || answer !== nw + word.slice(1) || word.length < 3) return { reject: 'answer is not the word with the first letter changed' };
        say = `Say ${word}. Now change ${word[0]} to ${nw}.`;
      } else return { reject: 'unknown operation' };
      const wrong = (g.wrong ?? []).map(lower);
      if (wrong.length !== 2 || wrong.some((x) => !isWord(x)) || new Set([answer, ...wrong]).size !== 3) return { reject: 'need 2 distinct wrong options' };
      return { item: { say, options: [answer, ...wrong].map((x) => ({ label: x, say: x })) }, key: `${word}|${op}` };
    },
  },
  letterSound: {
    describe: 'Letter-sound knowledge. The child hears a sound and taps the letter(s) that make it, from 3 choices.',
    rules: '"sound" is how the sound is said: single letters like "mmm", "buh", "sss", "tuh", or teams: "shh" (sh), "chuh, like in chair" (ch), "ee, like in tree" (ee), "oh, like in boat" (oa). "correct" is the letter(s); "wrong" are 2 other letters/teams that are easy to confuse. easy = single consonants; medium = look-alikes b/d/p/q, f/v; hard = letter teams sh/ch/th/ee/oa/ai/oo.',
    schema: S({ sound: str, correct: str, wrong: arr(str) }),
    build(g) {
      const correct = lower(g.correct), wrong = (g.wrong ?? []).map(lower), sound = lower(g.sound);
      if (!/^[a-z]{1,2}$/.test(correct) || wrong.some((x) => !/^[a-z]{1,2}$/.test(x)) || wrong.length !== 2 || new Set([correct, ...wrong]).size !== 3) return { reject: 'bad letters' };
      if (sound.length < 2 || sound.length > 40) return { reject: 'bad sound text' };
      const first = sound.replace(/,.*$/, '').trim();
      if (correct.length === 1 && first[0] !== correct) return { reject: 'sound does not begin with the letter' };
      return { item: { say: sound, options: [correct, ...wrong].map((x) => ({ label: x })) }, key: `${sound}|${correct}` };
    },
  },
  pictureNaming: {
    describe: 'Picture naming. The child sees ONE emoji and says its name aloud.',
    rules: '"word" is the everyday name of the emoji; "alternatives" are other names a child may reasonably say. Choose clearly recognisable objects. easy = very common (cat, apple); medium = common (turtle, scissors); hard = longer or less frequent (microscope, helicopter).',
    schema: S({ emoji: str, word: str, alternatives: arr(str) }, ['emoji', 'word']),
    build(g) {
      const word = lower(g.word);
      if (!/^[a-z ]{2,14}$/.test(word) || !hasEmoji(g.emoji)) return { reject: 'bad word/emoji' };
      const alt = (g.alternatives ?? []).map(lower).filter((x) => /^[a-z ]{2,14}$/.test(x) && x !== word);
      return { item: { emoji: clean(g.emoji), target: word, accept: [word, ...alt] }, key: word };
    },
  },
  wordReading: {
    describe: 'Word reading. The child reads ONE written word aloud.',
    rules: 'Real English words a primary-school child may know. easy = 3 letters (CVC: cat, sun, bed); medium = 4-5 letters with digraphs/blends (fish, ship, frog); hard = 6-9 letters, 2 syllables (rabbit, garden, umbrella).',
    schema: S({ word: str }),
    build(g, tier) {
      const w = lower(g.word);
      const [lo, hi] = { 1: [3, 3], 2: [4, 5], 3: [6, 9] }[tier];
      if (!isWord(w) || w.length < lo || w.length > hi) return { reject: `word length must be ${lo}-${hi}` };
      return { item: { target: w }, key: w };
    },
  },
  nonwordReading: {
    describe: 'Made-up word reading. The child sounds out ONE pronounceable made-up word (tests phonics, not memory).',
    rules: 'Pronounceable pseudo-words that are NOT real English words. easy = 3 letters CVC (fap, mib, zug); medium = 4 letters with blends/digraphs (blet, shom); hard = 5-8 letters (trand, bimlet, stroggle).',
    schema: S({ word: str }),
    build(g, tier) {
      const w = lower(g.word);
      const [lo, hi] = { 1: [3, 3], 2: [4, 5], 3: [5, 8] }[tier];
      if (!isWord(w) || w.length < lo || w.length > hi || !/[aeiou]/.test(w)) return { reject: 'not a pronounceable pseudo-word of the right length' };
      return { item: { target: w }, key: w };
    },
  },
  spelling: {
    describe: 'Spelling. The child sees an emoji, hears the word, and builds it from letter tiles.',
    rules: '"word" is the everyday name of the emoji. "extraLetters" are 2 decoy letters that are NOT in the word. easy = 3 letters (cat, sun); medium = 4-5 letters with digraphs (fish, ship, duck); hard = 5-7 letters (rabbit, basket).',
    schema: S({ emoji: str, word: str, extraLetters: str }),
    build(g, tier) {
      const w = lower(g.word), extra = lower(g.extraLetters).replace(/[^a-z]/g, '');
      const [lo, hi] = { 1: [3, 3], 2: [4, 5], 3: [5, 7] }[tier];
      if (!isWord(w) || w.length < lo || w.length > hi || !hasEmoji(g.emoji)) return { reject: 'bad word/emoji/length' };
      if (extra.length !== 2 || [...extra].some((ch) => w.includes(ch))) return { reject: 'extra letters must be 2 letters not in the word' };
      return { item: { emoji: clean(g.emoji), target: w, answer: w.split(''), distractors: extra.split('') }, key: w };
    },
  },
  readingComp: {
    describe: 'Early reading comprehension. The child silently reads ONE short sentence and picks the matching picture from 3.',
    rules: 'A sentence of 4-8 simple words. "correct" is the picture that matches the sentence exactly; the two "wrong" pictures each change exactly ONE detail (the animal, the place or the colour). Pictures are 1-2 emoji. easy = "The cat is on the bed."; medium = adds a place/animal change ("The fish is in the water."); hard = adds a colour/size ("I have a big red ball.").',
    schema: S({ sentence: str, correct: opt, wrong: arr(opt) }),
    build(g) {
      const s = clean(g.sentence);
      if (s.length < 10 || s.length > 60 || !/[.!]$/.test(s)) return { reject: 'sentence must be a short sentence ending in a full stop' };
      const c = g.correct, w = g.wrong ?? [];
      if (!c || w.length !== 2) return { reject: 'needs 1 correct + 2 wrong' };
      const labels = [lower(c.label), lower(w[0].label), lower(w[1].label)];
      if (new Set(labels).size !== 3 || labels.some((l) => l.length < 3)) return { reject: 'duplicate/empty options' };
      return { item: { passage: s, options: [pic(c.label, c.emoji), pic(w[0].label, w[0].emoji), pic(w[1].label, w[1].emoji)], only: 'junior' }, key: s.toLowerCase() };
    },
  },
  listening: {
    describe: 'Listening comprehension. The child hears a 2-3 sentence story and answers 3 questions by tapping one of 3 choices.',
    rules: 'A story of 2-3 simple sentences about an everyday event. 3 questions: (1) a detail, (2) another detail, (3) a cause/effect OR sequence question. Each question has the correct choice and 2 wrong ones (short phrases, optional emoji). easy = very short, concrete; hard = includes a reason ("so", "because").',
    schema: S({ story: str, questions: arr(S({ q: str, correct: opt, wrong: arr(opt), kind: str }, ['q', 'correct', 'wrong'])) }),
    build(g) {
      const story = clean(g.story);
      if (story.length < 40 || story.length > 330) return { reject: 'story length' };
      const qs = g.questions ?? [];
      if (qs.length !== 3) return { reject: 'needs 3 questions' };
      const questions = [];
      for (const q of qs) {
        if (!clean(q.q).endsWith('?') || !q.correct || (q.wrong ?? []).length !== 2) return { reject: 'bad question' };
        const labels = [q.correct, ...q.wrong].map((o) => lower(o.label));
        if (new Set(labels).size !== 3 || labels.some((l) => l.length < 2)) return { reject: 'bad question options' };
        const tag = /cause|why|because/i.test(q.kind ?? '') ? 'Cause / effect error' : /sequence|next|after|then/i.test(q.kind ?? '') ? 'Sequence error' : 'Wrong detail';
        questions.push({ q: clean(q.q), options: [q.correct, ...q.wrong].map((o) => pic(o.label, o.emoji ?? '')), correct: 0, tag });
      }
      return { item: { passage: story, questions }, key: story.toLowerCase().slice(0, 80) };
    },
  },
};

// Stations the agent cannot write for map to the closest one it can (the response is still recorded).
export const FALLBACK_SUBTEST = { ran: 'pictureNaming', oralReading: 'wordReading', fluency: 'wordReading' };

export function generableSubtest(subtest) {
  if (SUBTESTS[subtest]) return subtest;
  return FALLBACK_SUBTEST[subtest] ?? null;
}
