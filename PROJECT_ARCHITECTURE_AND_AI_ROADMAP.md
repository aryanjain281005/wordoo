# Readle (Wordoo) — Architecture, Screening & AI Integration Blueprint

This document captures the complete analysis, gameplay architecture, scientific screening design, and integration roadmap for **ElevenLabs** and **Google Gemini API** discussed for the Readle project.

---

## Table of Contents
1. [Pending Project Tasks & Assets Status](#1-pending-project-tasks--assets-status)
2. [MLH Hackathon Sponsor Opportunities](#2-mlh-hackathon-sponsor-opportunities)
3. [Full User Flow & Player Journey](#3-full-user-flow--player-journey)
4. [DALI-Aligned Screening & Scoring Science](#4-dali-aligned-screening--scoring-science)
5. [ElevenLabs Voice Integration Plan](#5-elevenlabs-voice-integration-plan)
6. [Gemini API Integration & Hybrid Architecture](#6-gemini-api-integration--hybrid-architecture)
7. [Prompt for Claude Code Implementation](#7-prompt-for-claude-code-implementation)

---

## 1. Pending Project Tasks & Assets Status

Based on an audit of [`YOUR_TASKS.md`](file:///Users/arpitjindal/VS%20Code/Wordoo/wordoo/YOUR_TASKS.md) against `assets/art/` and `assets/music/`:

### 🎨 Pending Images Checklist
* **Missing Backgrounds & Props:**
  * `bg.room.png` — Empty cosy bedroom (Phase 3 bedroom scene)
  * `prop.rocket.pearl.png` — Word Rocket pearl prop
* **World Map Floating Islands (1024 × 1024 icons):**
  * `island.forest.png`, `island.valley.png`, `island.ocean.png`, `island.village.png`, `island.treasure.png`, `island.castle.png`, `island.observatory.png`
* **Character Mouth Talk Frames (Edits of `.happy` with open mouth):**
  * `char.ullu.talk.png`
  * `char.kachhua.talk.png`
  * `char.bhalu.talk.png`
  * `char.madhu.talk.png`
  * `char.bolt.talk.png`
* **Optional High-Res Upgrades:**
  * 1024px single images for Milo expressions (`happy`, `talk`, `sad`, `surprised`, `thinking`, `cheer`) and guardian character sheets.

### 🎵 Music Credits
* Provide Pixabay page URLs for the 13 in-app `.ogg` tracks to compile `assets/music/CREDITS.txt`.

---

## 2. MLH Hackathon Sponsor Opportunities

Analysis of live MLH prize categories ([`https://www.mlh.com/events/prizes`](https://www.mlh.com/events/prizes)) mapped to Readle:

| Sponsor / Track | Integration Idea in Readle | Target Prize |
|---|---|---|
| **ElevenLabs** | Dynamic emotional character voices for Milo, Dadi, Kitabu, and guardians + AI story narration. | Wireless Earbuds |
| **Google Gemini API** | Personalized phonics story generator based on screening error tags + AI parent literacy coach. | MLH Swag Kits & GenAI Prizes |
| **Presage (Human Sensing)** | Front-camera focus & frustration detection to trigger adaptive difficulty & Milo hints. | Fitbit Inspire |
| **Backboard** | Long-term memory profile remembering a child's troubled words and story favorites across sessions. | Tile Essentials Pack |
| **Auth0** | Secure parent & educator login portal with PIN-gated screening reports. | Wireless Headphones |
| **Commit Fellowship** | Zero-to-founder startup sprint for real-world impact in childhood literacy screening. | Founder Sprint & Microgrants |

---

## 3. Full User Flow & Player Journey

```
                        📱 READLE USER EXPERIENCE FLOW
                        
 1. APP LAUNCH      ──► 2. STORY PROLOGUE ──► 3. SCREENING ADVENTURE
 Bright sky & Milo      Help Milo restore        Chapter 0: Broken Bridge
 greeting               Aksharpur               6 rapid disguised stations
                                                           │
                                                           ▼
 6. SESSION END     ◄── 5. GAMEPLAY LOOP  ◄── 4. WORLD MAP UNLOCKS
 High-five & Parent     Adaptive 10-step        7 Floating Islands
 Growth Dashboard       islands & mini-games    Personalized to profile
```

### Key Stages:
1. **Launch:** Warm, playful intro with Milo the Fox and Kitabu the Book (`bg.day.webp`).
2. **Prologue:** Gumsum the cloud swallowed the words of Aksharpur. The bridge to the Magic Forest broke.
3. **Screening (Chapter 0):** 6 bridge plank mini-tasks evaluating phonological awareness, letter-sound, decoding, rapid naming, oral reading, and comprehension without timers or test anxiety.
4. **Personalized Map:** 7 floating islands unlock. Starting levels (steps 1–7 of 10) are set independently per skill.
5. **Continuous Gameplay (v2.0):**
   * **No forced daily limits.**
   * **Quest Board:** Always presents 3 smart quests (1 high-need, 1 balanced, 1 confidence/stretch).
   * **Adaptive Engine:** Every answer updates ability ($\theta$) via Item Response Theory to maintain a ~78% target success rate.
6. **Wrap-up & Parent Mode:** High-five celebration. Parents access non-clinical DALI growth reports via PIN gate.

---

## 4. DALI-Aligned Screening & Scoring Science

### Where do the questions come from?
* Official DALI test materials are proprietary to the **National Brain Research Centre (NBRC)** and intentionally not published online to prevent test memorization.
* All items in `lib/screening/bank_en.dart` & `bank_hi.dart` were **custom-authored for Readle** using published DALI construct blueprints (Rhyme, First Sound, Deletion, RAN, Non-words, Real words, Spelling, Oral Reading).

### How does the child experience the test?
* The child **never answers all 150+ questions** in `bank_en.dart`.
* The battery filters questions by **Pool (A vs B)**, **Age Band (Junior vs Middle)**, and serves only **4–8 items per subtest**.
* If a child misses **3 questions in a row**, the subtest automatically discontinues and moves forward gently.

### The Scoring Math (`lib/screening/scorer.dart`):
1. **Z-Score Calculation:**
   $$Z_{\text{acc}} = \frac{\text{Accuracy} - \mu_{\text{acc}}}{\sigma_{\text{acc}}}$$
2. **Percentile Conversion:** Computed using the Abramowitz–Stegun normal cumulative distribution approximation (`normalCdf(z)`).
3. **Skill Bands:**
   * $\ge 50^{\text{th}}$ percentile $\rightarrow$ **Strong**
   * $16^{\text{th}} - 49^{\text{th}}$ percentile $\rightarrow$ **Developing**
   * $< 16^{\text{th}}$ percentile $\rightarrow$ **Needs Support**
4. **DALI 2-of-3 Domain Rule:** If $\ge 50\%$ of subtests in 2 or more domains fall into *Needs Support*, an **Elevated Indicator** is reported, advising consultation with a teacher/specialist.
5. **VoxLexi Speech Engine (`voxlexi.dart`):** Analyzes real-time microphone energy for pause frequency, hesitation latency, reading duration vs grade norms, and fuzzy phonetic alignment.

---

## 5. ElevenLabs Voice Integration Plan

### Curated Character-to-Voice Library Mapping:

| Character | Personality & Role | Recommended ElevenLabs Voice | Voice Settings |
|---|---|---|---|
| **Milo the Fox** | Cheerful, energetic, friendly companion | **Liam** or **Charlie** | Stability: 0.35, Similarity: 0.85 |
| **Dadi Kahani** | Wise, loving, grandmotherly narrator | **Glinda** or **Matilda** | Stability: 0.65, Similarity: 0.75 |
| **Gumsum Cloud** | Shy, giggly, childlike cloud | **Gigi** or **Mimi** (High pitch) | Stability: 0.40, Similarity: 0.80 |
| **Kitabu Book** | Quirky, scholarly, eccentric book | **Joseph** or **Thomas** | Stability: 0.55, Similarity: 0.80 |
| **Maestro Bhalu** | Dramatic, booming bear conductor | **Giovanni** or **Marcus** | Stability: 0.45, Similarity: 0.85 |
| **Arya the Archer** | Confident, spirited young hero | **Bella** or **Lily** | Stability: 0.50, Similarity: 0.80 |
| **Capt. Kachhua** | Hearty, old pirate sea turtle | **Clyde** or **Fin** | Stability: 0.60, Similarity: 0.85 |
| **Queen Madhu** | Regal, sweet, gentle bee queen | **Charlotte** or **Rachel** | Stability: 0.65, Similarity: 0.80 |

### Free Account Quota & Caching Architecture:
* **Monthly Limit:** Free tier provides **10,000 characters/month** (does not cut audio halfway; returns complete clips until quota expires).
* **Local Device Caching:** Store generated `.mp3` files in local device storage using `path_provider`. If a line (e.g., *"Ready, Explorer?"*) has already been generated, play the cached file with 0 API cost.
* **Fallback Strategy:** If offline or if quota error 429 occurs, fall back gracefully to bundled asset audio $\rightarrow$ `flutter_tts` $\rightarrow$ silent subtitle animation.

---

## 6. Gemini API Integration & Hybrid Architecture

### 🚫 Why NOT replace the existing engine:
* Replacing local scoring with an LLM risks calculation hallucinations, eliminates offline support, and introduces 1–2 second network latency during interactive gameplay.

### ⚡ The Recommended Hybrid Model (Local Engine + Gemini AI Booster):

```
 ┌───────────────────────────────────────────────────────────┐
 │                   LOCAL DART ENGINE                       │
 │  • 100% Offline Gameplay      • Instant 0ms response time │
 │  • Strict DALI Psychometrics  • Item Response Theory (θ)  │
 └─────────────────────────────┬─────────────────────────────┘
                               │ (Supercharged by)
                               ▼
 ┌───────────────────────────────────────────────────────────┐
 │                   GOOGLE GEMINI API                       │
 │  • Personalized Phonics Stories                           │
 │  • AI Parent Literacy Coach (English + Hindi)             │
 │  • Multimodal Physical Book OCR & Game Creator            │
 │  • Infinite Dynamic Quest Content                         │
 └───────────────────────────────────────────────────────────┘
```

### High-Impact Gemini Features:
1. **Custom Phonics Stories:** When a child struggles with specific error tags (e.g., `sh`/`ch` confusion), Gemini writes a tailored 4-sentence story starring Milo containing those target sounds.
2. **AI Parent Coach:** Translates raw percentile scores into empathetic, actionable at-home reading games and tips.
3. **Multimodal Book Reader (Gemini Vision):** Child snaps a photo of their school textbook $\rightarrow$ Gemini extracts the text and converts tricky words into a Readle mini-game.
4. **Infinite Adaptive Content:** Dynamically generates fresh question items matching the child's exact difficulty step when static banks run out.

---

## 7. Prompt for Claude Code Implementation

Use the following prompt when you are ready to instruct Claude Code to implement the ElevenLabs service:

```markdown
I want to integrate ElevenLabs Text-to-Speech (TTS) into our Readle (Wordoo) Flutter project for all in-game characters (Milo, Dadi Kahani, Gumsum, Kitabu, Island Guardians, etc.).

Before writing the implementation code, please analyze our existing architecture (cutscene player, audio manager, dialogue widgets, offline-first design) and answer the following questions with concrete technical recommendations:

### 1. Quota & Credit Failure Handling
- What happens if the ElevenLabs API credits run out mid-sentence or mid-game, or if the user goes offline / gets a 429 rate limit error?
- How should we architect a multi-tiered fallback strategy (e.g., Local Cache -> Bundled asset audio -> Standard Flutter TTS -> Silent text fallback) so the game never crashes or freezes?

### 2. Voice ID Management & Selection
- Should we hardcode specific pre-made Voice IDs in a configuration file (e.g., `lib/core/elevenlabs_config.dart`), or dynamically query the ElevenLabs `/v1/voices` endpoint at startup? Which approach is more resilient, faster, and saves API quota?
- How should we map character emotions and stability/similarity parameters per character in our existing Dart models?

### 3. Caching & Performance (Saving API Credits)
- Since static game lines (like cutscenes, greetings, and fixed game instructions) will be repeated often, how should we build an on-device caching system using `path_provider` so we only call ElevenLabs ONCE per unique line?
- Should we use full MP3 file downloads or real-time chunked streaming with `just_audio`? What is the recommended balance between playback latency and network stability on low-end Android devices?

### 4. Animation & Lip-Sync Synchronization
- How will the audio playback seamlessly synchronize with character sprite states (switching between `.happy`, `.talk`, and `.idle` mouth frames) across our current cutscene runner and game screens?

### 5. API Key Security & Configuration
- What is the safest way to pass the ElevenLabs API key (e.g., `--dart-define=ELEVENLABS_API_KEY=...` or `.env`) so we don't accidentally leak secrets into Git?
- Can we easily support multiple backup API keys in case the primary free key hits its monthly cap?

### 6. File Structure & Architectural Placement
- Where should the new service files live within our project structure (`lib/services/`, `lib/core/`, or `lib/audio/`), and how will it integrate with our existing `AudioManager` / `SpeechEngine`?

Please provide a clear design blueprint and step-by-step implementation plan based on our codebase.
```
