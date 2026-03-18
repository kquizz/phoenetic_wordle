# Phonetic Wordle — Design Document

## Concept

A Wordle-style word guessing game where feedback is based on phonemes (sounds) rather than letters. Players type normal English words, which are converted to IPA (International Phonetic Alphabet) representations. The grid displays IPA symbols with green/yellow/gray feedback based on phoneme matches.

## Core Rules

- Target words have exactly **5 phonemes**
- Players get **6 guesses**
- Guesses must be real English words that produce exactly 5 phonemes
- Words with identical pronunciations (e.g., "knight"/"night") are treated as the same guess
- Two modes: **daily puzzle** (one per day, same for everyone) and **practice** (unlimited, random)

## Data Model

### Word
Pre-seeded from CMU Pronouncing Dictionary (filtered to 5-phoneme words only).

| Column | Type | Notes |
|--------|------|-------|
| text | string | English word ("knight") |
| ipa | string | IPA representation ("/naɪt/") |
| phonemes | string array | Individual phonemes ["n", "aɪ", "t"] |
| phoneme_count | integer | Indexed, always 5 for gameplay words |

### DailyPuzzle

| Column | Type | Notes |
|--------|------|-------|
| date | date | Unique index, one per day |
| word_id | references | The target Word |

### Game
Tracks a play session. No user accounts — session-based.

| Column | Type | Notes |
|--------|------|-------|
| daily_puzzle_id | references | Nullable — nil for practice mode |
| session_id | string | Ties to browser session |
| target_word_id | references | The target Word |
| guesses | JSON | Array of guess data |
| status | enum | in_progress / won / lost |
| completed_at | datetime | |

## Phoneme Engine

### CMU to IPA Pipeline
- CMU dict uses ARPAbet notation (`N AY1 T` for "night")
- At seed time, each ARPAbet phoneme is mapped to its IPA equivalent
- A `db/seeds` task parses the CMU dict file, converts to IPA, populates the `words` table
- Only 5-phoneme words are kept

### GuessEvaluator Service
- Takes guessed word's phoneme array and target's phoneme array
- Returns array of 5 results: `correct` (green), `present` (yellow), `absent` (gray)
- Uses Wordle's algorithm: exact matches first, then leftover pool for present/absent (handles duplicate phonemes correctly)

### GuessValidator Service
- Checks word exists in the dictionary
- Checks it produces exactly 5 phonemes
- Returns specific error messages ("not in word list" vs "that word has 3 sounds, you need 5")

## Request Flow

### Routes
- `GET /` — landing page, links to daily and practice
- `GET /daily` — starts/resumes today's daily game
- `GET /practice` — starts a new practice game
- `POST /games/:id/guesses` — submit a guess, returns Turbo Stream

### Guess Cycle
1. Player types on keyboard (physical or on-screen) — Stimulus captures input, displays letters in current row
2. On submit, Stimulus POSTs the word to the server
3. Controller calls GuessValidator then GuessEvaluator
4. Turbo Stream replaces the current row with IPA phonemes + color coding, updates on-screen keyboard
5. On game over (won/lost), stream reveals answer and shows share button

## UI

### Grid
- 6 rows x 5 columns
- All cells uniformly sized to fit the widest IPA symbol (diphthongs like /aɪ/)
- Before evaluation: cells show typed letters
- After evaluation: cells flip to reveal IPA phonemes with green/yellow/gray backgrounds

### Keyboard
- Standard QWERTY on-screen keyboard (players type English words)
- Simple coloring: gray out letters from fully-absent guesses only
- No green/yellow on keys (letter-to-phoneme mapping is not 1:1, would be misleading)

### Share
- Button appears on game completion
- Copies to clipboard: "Phonetic Wordle #42 🔊 4/6" followed by emoji grid (🟩🟨⬛)

## Tech Stack

- **Rails 8** with SQLite
- **Turbo + Stimulus** via importmap (no Node/webpack)
- **Plain CSS** via Propshaft (no Tailwind)
- No special gems — CMU dict is a flat text file parsed at seed time

### Stimulus Controllers
- `game_controller` — keyboard input, current row tracking, letter display, form submission, tile flip animations
- `share_controller` — copies result to clipboard
- `keyboard_controller` — on-screen keyboard input and key state coloring

### Testing
- Minitest (Rails default)
- Model tests for GuessEvaluator and GuessValidator
- System tests with Capybara for full guess flow
