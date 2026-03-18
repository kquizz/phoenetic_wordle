# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Phonetic Wordle — a Wordle-style game where feedback is based on phonemes (IPA) instead of letters. Players type English words, which are converted to IPA via the CMU Pronouncing Dictionary. Target words have exactly 5 phonemes. 6 guesses allowed.

## Commands

- `bin/rails server` — start dev server
- `bin/rails test` — run all unit/integration tests
- `bin/rails test test/path/to/test.rb` — run single test file
- `bin/rails test test/path/to/test.rb:LINE` — run single test
- `bin/rails test:system` — run Capybara system tests (requires Chrome)
- `bin/rails db:seed` — seed words from CMU dictionary (required before first run)
- `bin/rails db:migrate` — run pending migrations

## Architecture

Rails 8 + SQLite, fully server-rendered with Turbo Streams and Stimulus. No SPA, no Node, no Tailwind.

### Services (app/services/)
- **ArpabetToIpa** — converts ARPAbet phoneme notation to IPA symbols. Full 39-phoneme mapping.
- **CmuDictParser** — parses CMU dictionary file into Word model attributes at seed time.
- **GuessValidator** — validates a guess exists in dictionary and has exactly 5 phonemes. Returns a Result struct.
- **GuessEvaluator** — Wordle matching algorithm on phoneme arrays. Two-pass: exact matches first, then present/absent with duplicate handling.

### Stimulus controllers (app/javascript/controllers/)
- **game_controller** — text input, guess submission via Turbo Stream, game-over state
- **keyboard_controller** — on-screen QWERTY keyboard, types into game input
- **share_controller** — copies emoji result grid to clipboard

### Game flow
1. Player types English word → POST to GuessesController
2. Server validates (GuessValidator) → evaluates (GuessEvaluator)
3. Turbo Stream replaces grid row with IPA phonemes + green/yellow/gray coloring
4. Game state tracked in Game model, tied to browser session

### Data
- Words seeded from CMU Pronouncing Dictionary (db/cmu_dict/, gitignored). ~24k five-phoneme words.
- DailyPuzzle assigns one random word per calendar date
- Game stores guesses as JSON array with phonemes and evaluation results
- Two modes: daily (one per day, shareable) and practice (unlimited, random)
