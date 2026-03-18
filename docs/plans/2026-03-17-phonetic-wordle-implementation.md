# Phonetic Wordle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a Wordle-style game where guesses are evaluated on phonemes (IPA) instead of letters, using Rails 8 + Stimulus.

**Architecture:** Fully server-rendered Rails app. Players type English words, server converts to phonemes via CMU dictionary lookup, evaluates against target, returns Turbo Stream updates. Game state lives in the database, tied to browser sessions.

**Tech Stack:** Rails 8, SQLite, Turbo, Stimulus, Minitest, importmap, Propshaft, plain CSS.

---

### Task 1: Scaffold Rails App

**Step 1: Generate new Rails app**

```bash
cd /Users/kquillen/Code/games/phoenetic_wordle
rails new . --database=sqlite3 --css=plain --skip-jbuilder --skip-action-mailbox --skip-action-mailer --skip-active-storage --skip-action-cable --skip-action-text
```

Accept overwrite of `.gitignore` if prompted. Decline overwrite of existing files you want to keep (like `docs/` or `CLAUDE.md`).

**Step 2: Verify it boots**

```bash
bin/rails server
```

Visit http://localhost:3000 — should see Rails welcome page. Stop server with Ctrl-C.

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: scaffold Rails 8 app"
```

---

### Task 2: ARPAbet to IPA Mapping

**Files:**
- Create: `app/services/arpabet_to_ipa.rb`
- Test: `test/services/arpabet_to_ipa_test.rb`

**Step 1: Create test directory and write failing test**

```bash
mkdir -p test/services
```

```ruby
# test/services/arpabet_to_ipa_test.rb
require "test_helper"

class ArpabetToIpaTest < ActiveSupport::TestCase
  test "converts single consonant" do
    assert_equal "k", ArpabetToIpa.convert("K")
  end

  test "converts vowel with stress marker" do
    assert_equal "æ", ArpabetToIpa.convert("AE1")
  end

  test "converts vowel without stress marker" do
    assert_equal "æ", ArpabetToIpa.convert("AE0")
  end

  test "converts diphthong" do
    assert_equal "aɪ", ArpabetToIpa.convert("AY1")
  end

  test "converts full phoneme sequence" do
    # "cat" = K AE1 T
    assert_equal ["k", "æ", "t"], ArpabetToIpa.convert_sequence(["K", "AE1", "T"])
  end

  test "converts night phoneme sequence" do
    # "night" = N AY1 T
    assert_equal ["n", "aɪ", "t"], ArpabetToIpa.convert_sequence(["N", "AY1", "T"])
  end

  test "raises on unknown phoneme" do
    assert_raises(ArpabetToIpa::UnknownPhoneme) do
      ArpabetToIpa.convert("ZZZ")
    end
  end
end
```

**Step 2: Run test to verify it fails**

```bash
bin/rails test test/services/arpabet_to_ipa_test.rb
```

Expected: NameError — `ArpabetToIpa` not defined.

**Step 3: Write implementation**

```bash
mkdir -p app/services
```

```ruby
# app/services/arpabet_to_ipa.rb
class ArpabetToIpa
  class UnknownPhoneme < StandardError; end

  # Full ARPAbet to IPA mapping
  # Reference: https://en.wikipedia.org/wiki/ARPABET
  MAPPING = {
    # Vowels (monophthongs)
    "AA" => "ɑ",   # odd
    "AE" => "æ",   # at
    "AH" => "ʌ",   # hut
    "AO" => "ɔ",   # ought
    "EH" => "ɛ",   # ed
    "ER" => "ɝ",   # hurt
    "IH" => "ɪ",   # it
    "IY" => "i",   # eat
    "UH" => "ʊ",   # hood
    "UW" => "u",   # two
    # Diphthongs
    "AW" => "aʊ",  # cow
    "AY" => "aɪ",  # my
    "EY" => "eɪ",  # ate
    "OW" => "oʊ",  # oat
    "OY" => "ɔɪ",  # toy
    # Consonants
    "B"  => "b",
    "CH" => "tʃ",
    "D"  => "d",
    "DH" => "ð",   # the
    "F"  => "f",
    "G"  => "ɡ",
    "HH" => "h",
    "JH" => "dʒ",  # judge
    "K"  => "k",
    "L"  => "l",
    "M"  => "m",
    "N"  => "n",
    "NG" => "ŋ",   # sing
    "P"  => "p",
    "R"  => "ɹ",
    "S"  => "s",
    "SH" => "ʃ",   # she
    "T"  => "t",
    "TH" => "θ",   # think
    "V"  => "v",
    "W"  => "w",
    "Y"  => "j",
    "Z"  => "z",
    "ZH" => "ʒ"    # measure
  }.freeze

  # Convert a single ARPAbet phoneme (e.g., "AE1") to IPA
  def self.convert(arpabet)
    # Strip stress marker (0, 1, 2) from end
    base = arpabet.gsub(/[012]$/, "")
    MAPPING.fetch(base) { raise UnknownPhoneme, "Unknown ARPAbet phoneme: #{arpabet}" }
  end

  # Convert array of ARPAbet phonemes to array of IPA phonemes
  def self.convert_sequence(arpabet_phonemes)
    arpabet_phonemes.map { |p| convert(p) }
  end
end
```

**Step 4: Run tests to verify they pass**

```bash
bin/rails test test/services/arpabet_to_ipa_test.rb
```

Expected: All 7 tests pass.

**Step 5: Commit**

```bash
git add app/services/arpabet_to_ipa.rb test/services/arpabet_to_ipa_test.rb
git commit -m "feat: add ARPAbet to IPA conversion service"
```

---

### Task 3: Word Model and CMU Dictionary Seed

**Files:**
- Create: `db/migrate/..._create_words.rb` (via generator)
- Create: `app/models/word.rb` (via generator)
- Create: `db/cmu_dict/cmudict-0.7b.txt` (download)
- Create: `app/services/cmu_dict_parser.rb`
- Create: `db/seeds.rb`
- Test: `test/models/word_test.rb`
- Test: `test/services/cmu_dict_parser_test.rb`

**Step 1: Generate Word model**

```bash
bin/rails generate model Word text:string ipa:string phonemes:json phoneme_count:integer
```

**Step 2: Add index and constraints to migration**

Edit the generated migration file to add:

```ruby
class CreateWords < ActiveRecord::Migration[8.0]
  def change
    create_table :words do |t|
      t.string :text, null: false
      t.string :ipa, null: false
      t.json :phonemes, null: false
      t.integer :phoneme_count, null: false

      t.timestamps
    end

    add_index :words, :text, unique: true
    add_index :words, :phoneme_count
  end
end
```

**Step 3: Run migration**

```bash
bin/rails db:migrate
```

**Step 4: Write Word model validations**

```ruby
# app/models/word.rb
class Word < ApplicationRecord
  validates :text, presence: true, uniqueness: true
  validates :ipa, presence: true
  validates :phonemes, presence: true
  validates :phoneme_count, presence: true

  scope :five_phonemes, -> { where(phoneme_count: 5) }
end
```

**Step 5: Write Word model test**

```ruby
# test/models/word_test.rb
require "test_helper"

class WordTest < ActiveSupport::TestCase
  test "valid word" do
    word = Word.new(text: "night", ipa: "naɪt", phonemes: ["n", "aɪ", "t"], phoneme_count: 3)
    assert word.valid?
  end

  test "requires text" do
    word = Word.new(text: nil, ipa: "naɪt", phonemes: ["n", "aɪ", "t"], phoneme_count: 3)
    assert_not word.valid?
  end

  test "text must be unique" do
    Word.create!(text: "night", ipa: "naɪt", phonemes: ["n", "aɪ", "t"], phoneme_count: 3)
    word = Word.new(text: "night", ipa: "naɪt", phonemes: ["n", "aɪ", "t"], phoneme_count: 3)
    assert_not word.valid?
  end

  test "five_phonemes scope" do
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3)
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    assert_equal 1, Word.five_phonemes.count
    assert_equal "plant", Word.five_phonemes.first.text
  end
end
```

**Step 6: Run tests**

```bash
bin/rails test test/models/word_test.rb
```

Expected: All pass.

**Step 7: Download CMU dictionary**

```bash
mkdir -p db/cmu_dict
curl -L -o db/cmu_dict/cmudict-0.7b.txt "https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict"
```

Note: The `.dict` format has lines like: `night N AY1 T`. If the file format uses `NIGHT  N AY1 T` (uppercase with double space), adjust parser accordingly. Check the file after download.

**Step 8: Write CMU dict parser test**

```ruby
# test/services/cmu_dict_parser_test.rb
require "test_helper"

class CmuDictParserTest < ActiveSupport::TestCase
  test "parses a line into word and arpabet phonemes" do
    line = "night N AY1 T"
    result = CmuDictParser.parse_line(line)
    assert_equal "night", result[:word]
    assert_equal ["N", "AY1", "T"], result[:arpabet]
  end

  test "skips comment lines" do
    line = ";;; this is a comment"
    assert_nil CmuDictParser.parse_line(line)
  end

  test "handles alternate pronunciations like word(2)" do
    line = "read(2) R EH1 D"
    result = CmuDictParser.parse_line(line)
    assert_nil result  # skip alternates
  end

  test "builds word attributes from parsed line" do
    line = "night N AY1 T"
    attrs = CmuDictParser.line_to_word_attrs(line)
    assert_equal "night", attrs[:text]
    assert_equal ["n", "aɪ", "t"], attrs[:phonemes]
    assert_equal "naɪt", attrs[:ipa]
    assert_equal 3, attrs[:phoneme_count]
  end
end
```

**Step 9: Write CMU dict parser**

```ruby
# app/services/cmu_dict_parser.rb
class CmuDictParser
  # Parse one line of the CMU dict file
  # Format: "word P1 P2 P3" or "WORD  P1 P2 P3"
  def self.parse_line(line)
    line = line.strip
    return nil if line.start_with?(";;;") || line.start_with?("#") || line.empty?

    # Skip alternate pronunciations like "word(2)"
    return nil if line.match?(/\(\d+\)/)

    parts = line.split(/\s+/)
    word = parts[0].downcase
    arpabet = parts[1..]

    { word: word, arpabet: arpabet }
  end

  # Convert a parsed line to Word model attributes
  def self.line_to_word_attrs(line)
    parsed = parse_line(line)
    return nil unless parsed

    ipa_phonemes = ArpabetToIpa.convert_sequence(parsed[:arpabet])

    {
      text: parsed[:word],
      phonemes: ipa_phonemes,
      ipa: ipa_phonemes.join,
      phoneme_count: ipa_phonemes.length
    }
  end

  # Parse entire CMU dict file, yield word attributes
  def self.parse_file(path)
    File.foreach(path) do |line|
      attrs = line_to_word_attrs(line)
      next unless attrs
      yield attrs
    end
  end
end
```

**Step 10: Run parser tests**

```bash
bin/rails test test/services/cmu_dict_parser_test.rb
```

Expected: All pass.

**Step 11: Write seed file**

```ruby
# db/seeds.rb
dict_path = Rails.root.join("db", "cmu_dict", "cmudict-0.7b.txt")

unless File.exist?(dict_path)
  puts "CMU dictionary not found at #{dict_path}"
  puts "Download it: curl -L -o db/cmu_dict/cmudict-0.7b.txt https://raw.githubusercontent.com/cmusphinx/cmudict/master/cmudict.dict"
  exit 1
end

puts "Parsing CMU dictionary..."
count = 0
batch = []

CmuDictParser.parse_file(dict_path) do |attrs|
  next unless attrs[:phoneme_count] == 5

  batch << attrs
  if batch.size >= 1000
    Word.insert_all(batch, unique_by: :text)
    count += batch.size
    batch.clear
    print "."
  end
end

# Insert remaining batch
if batch.any?
  Word.insert_all(batch, unique_by: :text)
  count += batch.size
end

puts "\nSeeded #{count} five-phoneme words (#{Word.five_phonemes.count} in database)"
```

**Step 12: Run seed**

```bash
bin/rails db:seed
```

Expected: Prints progress dots, then summary of seeded words.

**Step 13: Verify in console**

```bash
bin/rails runner "puts Word.five_phonemes.count; puts Word.five_phonemes.order('RANDOM()').limit(5).pluck(:text, :ipa).inspect"
```

Expected: Shows count and 5 random words with IPA.

**Step 14: Commit**

```bash
git add -A
git commit -m "feat: add Word model with CMU dictionary seed and parser"
```

---

### Task 4: GuessValidator Service

**Files:**
- Create: `app/services/guess_validator.rb`
- Test: `test/services/guess_validator_test.rb`

**Step 1: Write failing test**

```ruby
# test/services/guess_validator_test.rb
require "test_helper"

class GuessValidatorTest < ActiveSupport::TestCase
  setup do
    # A 5-phoneme word
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    # A 3-phoneme word
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3)
  end

  test "valid 5-phoneme word returns success" do
    result = GuessValidator.validate("plant")
    assert result.valid?
    assert_equal ["p", "l", "æ", "n", "t"], result.phonemes
  end

  test "word not in dictionary returns error" do
    result = GuessValidator.validate("xyzzy")
    assert_not result.valid?
    assert_equal :not_in_dictionary, result.error
  end

  test "word with wrong phoneme count returns error" do
    result = GuessValidator.validate("cat")
    assert_not result.valid?
    assert_equal :wrong_phoneme_count, result.error
    assert_equal 3, result.phoneme_count
  end

  test "normalizes input to lowercase" do
    result = GuessValidator.validate("PLANT")
    assert result.valid?
  end

  test "rejects blank input" do
    result = GuessValidator.validate("")
    assert_not result.valid?
    assert_equal :blank, result.error
  end
end
```

**Step 2: Run to verify failure**

```bash
bin/rails test test/services/guess_validator_test.rb
```

Expected: NameError — `GuessValidator` not defined.

**Step 3: Write implementation**

```ruby
# app/services/guess_validator.rb
class GuessValidator
  Result = Struct.new(:valid?, :error, :phonemes, :phoneme_count, :word, keyword_init: true)

  def self.validate(input)
    text = input.to_s.strip.downcase

    if text.empty?
      return Result.new(valid?: false, error: :blank)
    end

    word = Word.find_by(text: text)

    unless word
      return Result.new(valid?: false, error: :not_in_dictionary)
    end

    unless word.phoneme_count == 5
      return Result.new(valid?: false, error: :wrong_phoneme_count, phoneme_count: word.phoneme_count)
    end

    Result.new(valid?: true, phonemes: word.phonemes, word: word)
  end
end
```

**Step 4: Run tests**

```bash
bin/rails test test/services/guess_validator_test.rb
```

Expected: All 5 pass.

**Step 5: Commit**

```bash
git add app/services/guess_validator.rb test/services/guess_validator_test.rb
git commit -m "feat: add GuessValidator service"
```

---

### Task 5: GuessEvaluator Service

**Files:**
- Create: `app/services/guess_evaluator.rb`
- Test: `test/services/guess_evaluator_test.rb`

This is the core game logic — Wordle's matching algorithm applied to phonemes.

**Step 1: Write failing tests**

```ruby
# test/services/guess_evaluator_test.rb
require "test_helper"

class GuessEvaluatorTest < ActiveSupport::TestCase
  test "all correct" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["p", "l", "æ", "n", "t"]
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:correct, :correct, :correct, :correct, :correct], result
  end

  test "all absent" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["b", "ɹ", "ɪ", "ŋ", "k"]
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:absent, :absent, :absent, :absent, :absent], result
  end

  test "some present, some correct" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["t", "l", "n", "æ", "p"]
    # t is present (exists but wrong position)
    # l is correct
    # n is present
    # æ is present
    # p is present
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:present, :correct, :present, :present, :present], result
  end

  test "duplicate phoneme in guess — one correct, one absent" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["p", "p", "æ", "n", "t"]
    # first p: correct
    # second p: absent (only one p in target, already matched)
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:correct, :absent, :correct, :correct, :correct], result
  end

  test "duplicate phoneme in guess — one present, one absent" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["b", "p", "æ", "p", "t"]
    # first p (position 1): present (p exists at position 0)
    # second p (position 3): absent (only one p, already accounted for)
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:absent, :present, :correct, :absent, :correct], result
  end

  test "duplicate phoneme in target" do
    target  = ["p", "æ", "p", "æ", "t"]
    guess   = ["p", "b", "b", "æ", "t"]
    # position 0 p: correct
    # position 3 æ: correct
    # position 4 t: correct
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:correct, :absent, :absent, :correct, :correct], result
  end
end
```

**Step 2: Run to verify failure**

```bash
bin/rails test test/services/guess_evaluator_test.rb
```

Expected: NameError — `GuessEvaluator` not defined.

**Step 3: Write implementation**

```ruby
# app/services/guess_evaluator.rb
class GuessEvaluator
  # Evaluate a guess against a target using Wordle's algorithm.
  # Both guess and target are arrays of 5 phoneme strings.
  # Returns array of 5 symbols: :correct, :present, or :absent
  def self.evaluate(guess:, target:)
    result = Array.new(5, :absent)
    target_remaining = target.dup

    # Pass 1: Mark exact matches (correct)
    guess.each_with_index do |phoneme, i|
      if phoneme == target[i]
        result[i] = :correct
        target_remaining[i] = nil
      end
    end

    # Pass 2: Mark present (right phoneme, wrong position)
    guess.each_with_index do |phoneme, i|
      next if result[i] == :correct

      match_index = target_remaining.index(phoneme)
      if match_index
        result[i] = :present
        target_remaining[match_index] = nil
      end
    end

    result
  end
end
```

**Step 4: Run tests**

```bash
bin/rails test test/services/guess_evaluator_test.rb
```

Expected: All 6 pass.

**Step 5: Commit**

```bash
git add app/services/guess_evaluator.rb test/services/guess_evaluator_test.rb
git commit -m "feat: add GuessEvaluator service with Wordle algorithm"
```

---

### Task 6: Game and DailyPuzzle Models

**Files:**
- Create: `db/migrate/..._create_daily_puzzles.rb` (via generator)
- Create: `db/migrate/..._create_games.rb` (via generator)
- Modify: `app/models/game.rb`
- Modify: `app/models/daily_puzzle.rb`
- Test: `test/models/game_test.rb`
- Test: `test/models/daily_puzzle_test.rb`

**Step 1: Generate DailyPuzzle model**

```bash
bin/rails generate model DailyPuzzle date:date word:references
```

**Step 2: Edit DailyPuzzle migration for unique constraint**

```ruby
class CreateDailyPuzzles < ActiveRecord::Migration[8.0]
  def change
    create_table :daily_puzzles do |t|
      t.date :date, null: false
      t.references :word, null: false, foreign_key: true

      t.timestamps
    end

    add_index :daily_puzzles, :date, unique: true
  end
end
```

**Step 3: Generate Game model**

```bash
bin/rails generate model Game daily_puzzle:references session_id:string target_word:references guesses:json status:integer completed_at:datetime
```

**Step 4: Edit Game migration**

```ruby
class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      t.references :daily_puzzle, null: true, foreign_key: true
      t.string :session_id, null: false
      t.references :target_word, null: false, foreign_key: { to_table: :words }
      t.json :guesses, null: false, default: "[]"
      t.integer :status, null: false, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    add_index :games, [:session_id, :daily_puzzle_id], unique: true
  end
end
```

**Step 5: Run migrations**

```bash
bin/rails db:migrate
```

**Step 6: Write DailyPuzzle model**

```ruby
# app/models/daily_puzzle.rb
class DailyPuzzle < ApplicationRecord
  belongs_to :word

  validates :date, presence: true, uniqueness: true

  def self.for_today
    today = Date.current
    find_or_create_by!(date: today) do |puzzle|
      puzzle.word = Word.five_phonemes.order("RANDOM()").first!
    end
  end

  def puzzle_number
    # Number of days since launch (or a fixed epoch)
    (date - Date.new(2026, 1, 1)).to_i
  end
end
```

**Step 7: Write Game model**

```ruby
# app/models/game.rb
class Game < ApplicationRecord
  belongs_to :daily_puzzle, optional: true
  belongs_to :target_word, class_name: "Word"

  enum :status, { in_progress: 0, won: 1, lost: 2 }

  MAX_GUESSES = 6

  validates :session_id, presence: true
  validates :status, presence: true

  def add_guess!(word_text, phonemes, evaluation)
    guesses_array = guesses || []
    guesses_array << {
      word: word_text,
      phonemes: phonemes,
      evaluation: evaluation
    }
    self.guesses = guesses_array

    if evaluation.all? { |e| e == "correct" }
      self.status = :won
      self.completed_at = Time.current
    elsif guesses_array.length >= MAX_GUESSES
      self.status = :lost
      self.completed_at = Time.current
    end

    save!
  end

  def current_guess_number
    (guesses || []).length
  end

  def over?
    won? || lost?
  end

  def guesses_remaining
    MAX_GUESSES - current_guess_number
  end
end
```

**Step 8: Write Game model test**

```ruby
# test/models/game_test.rb
require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @target = Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    @game = Game.create!(session_id: "test-session", target_word: @target)
  end

  test "starts in_progress with empty guesses" do
    assert @game.in_progress?
    assert_equal 0, @game.current_guess_number
    assert_equal 6, @game.guesses_remaining
  end

  test "add_guess! appends guess data" do
    @game.add_guess!("crane", ["k", "ɹ", "eɪ", "n", "t"], ["absent", "absent", "absent", "correct", "correct"])
    assert_equal 1, @game.current_guess_number
    assert @game.in_progress?
  end

  test "game is won when all correct" do
    @game.add_guess!("plant", ["p", "l", "æ", "n", "t"], ["correct", "correct", "correct", "correct", "correct"])
    assert @game.won?
    assert @game.over?
    assert_not_nil @game.completed_at
  end

  test "game is lost after 6 incorrect guesses" do
    6.times do |i|
      @game.add_guess!("wrong#{i}", ["b", "ɹ", "ɪ", "ŋ", "k"], ["absent", "absent", "absent", "absent", "absent"])
    end
    assert @game.lost?
    assert @game.over?
  end

  test "guesses_remaining decrements" do
    @game.add_guess!("crane", ["k", "ɹ", "eɪ", "n", "t"], ["absent", "absent", "absent", "correct", "correct"])
    assert_equal 5, @game.guesses_remaining
  end
end
```

**Step 9: Write DailyPuzzle test**

```ruby
# test/models/daily_puzzle_test.rb
require "test_helper"

class DailyPuzzleTest < ActiveSupport::TestCase
  setup do
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
  end

  test "for_today creates puzzle for today" do
    puzzle = DailyPuzzle.for_today
    assert_equal Date.current, puzzle.date
    assert_equal "plant", puzzle.word.text
  end

  test "for_today returns same puzzle on second call" do
    puzzle1 = DailyPuzzle.for_today
    puzzle2 = DailyPuzzle.for_today
    assert_equal puzzle1.id, puzzle2.id
  end

  test "puzzle_number counts days from epoch" do
    puzzle = DailyPuzzle.create!(date: Date.new(2026, 1, 11), word: Word.first)
    assert_equal 10, puzzle.puzzle_number
  end
end
```

**Step 10: Run all model tests**

```bash
bin/rails test test/models/
```

Expected: All pass.

**Step 11: Commit**

```bash
git add -A
git commit -m "feat: add Game and DailyPuzzle models"
```

---

### Task 7: Controllers and Routes

**Files:**
- Create: `app/controllers/pages_controller.rb`
- Create: `app/controllers/games_controller.rb`
- Create: `app/controllers/guesses_controller.rb`
- Modify: `config/routes.rb`
- Test: `test/controllers/games_controller_test.rb`
- Test: `test/controllers/guesses_controller_test.rb`

**Step 1: Write routes**

```ruby
# config/routes.rb
Rails.application.routes.draw do
  root "pages#home"

  get "daily", to: "games#daily"
  get "practice", to: "games#practice"

  resources :games, only: [] do
    resources :guesses, only: [:create]
  end
end
```

**Step 2: Write PagesController**

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def home
  end
end
```

**Step 3: Write GamesController**

```ruby
# app/controllers/games_controller.rb
class GamesController < ApplicationController
  def daily
    puzzle = DailyPuzzle.for_today
    @game = Game.find_or_create_by!(session_id: session.id.to_s, daily_puzzle: puzzle) do |game|
      game.target_word = puzzle.word
    end
    render :show
  end

  def practice
    @game = Game.create!(
      session_id: session.id.to_s,
      target_word: Word.five_phonemes.order("RANDOM()").first!
    )
    redirect_to_game(@game)
  end

  private

  def redirect_to_game(game)
    redirect_to daily_path if game.daily_puzzle_id
    # For practice, render directly since there's no stable URL
    render :show
  end
end
```

**Step 4: Write GuessesController**

```ruby
# app/controllers/guesses_controller.rb
class GuessesController < ApplicationController
  def create
    @game = Game.find(params[:game_id])
    @guess_text = params[:guess].to_s.strip.downcase

    if @game.over?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("error", partial: "games/error", locals: { message: "Game is already over" }) }
      end
      return
    end

    validation = GuessValidator.validate(@guess_text)

    unless validation.valid?
      message = case validation.error
                when :blank then "Please enter a word"
                when :not_in_dictionary then "Not in word list"
                when :wrong_phoneme_count then "That word has #{validation.phoneme_count} sounds, you need 5"
                end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("error", partial: "games/error", locals: { message: message }) }
      end
      return
    end

    evaluation = GuessEvaluator.evaluate(
      guess: validation.phonemes,
      target: @game.target_word.phonemes
    )

    @game.add_guess!(@guess_text, validation.phonemes, evaluation.map(&:to_s))
    @guess_index = @game.current_guess_number - 1
    @guess_data = @game.guesses[@guess_index]

    respond_to do |format|
      format.turbo_stream
    end
  end
end
```

**Step 5: Write controller tests**

```ruby
# test/controllers/games_controller_test.rb
require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
  end

  test "daily creates game and renders show" do
    get daily_path
    assert_response :success
  end

  test "daily returns same game on second visit" do
    get daily_path
    get daily_path
    assert_equal 1, Game.count
  end

  test "practice creates new game" do
    get practice_path
    assert_response :success
    assert_equal 1, Game.count
  end
end
```

```ruby
# test/controllers/guesses_controller_test.rb
require "test_helper"

class GuessesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @target = Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    Word.create!(text: "crane", ipa: "kɹeɪn", phonemes: ["k", "ɹ", "eɪ", "n"], phoneme_count: 4)
    Word.create!(text: "bland", ipa: "blænd", phonemes: ["b", "l", "æ", "n", "d"], phoneme_count: 5)
  end

  test "valid guess returns turbo stream" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "bland" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
  end

  test "invalid word returns error" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "xyzzy" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/Not in word list/, response.body)
  end

  test "wrong phoneme count returns error" do
    game = Game.create!(session_id: "test", target_word: @target)
    post game_guesses_path(game), params: { guess: "crane" }, headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match(/4 sounds/, response.body)
  end
end
```

**Step 6: Run controller tests**

```bash
bin/rails test test/controllers/
```

Expected: All pass.

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add controllers and routes for game flow"
```

---

### Task 8: Views — Layout, Home, and Game Board

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Create: `app/views/pages/home.html.erb`
- Create: `app/views/games/show.html.erb`
- Create: `app/views/games/_board.html.erb`
- Create: `app/views/games/_row.html.erb`
- Create: `app/views/games/_error.html.erb`
- Create: `app/views/guesses/create.turbo_stream.erb`
- Create: `app/assets/stylesheets/application.css`

This task creates all the views. The CSS and HTML structure are detailed here since the grid layout is central to the game.

**Step 1: Write application layout**

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html>
  <head>
    <title>Phonetic Wordle</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application" %>
    <%= javascript_importmap_tags %>
  </head>
  <body>
    <header class="header">
      <h1><a href="<%= root_path %>">Phonetic Wordle</a></h1>
    </header>
    <main class="main">
      <%= yield %>
    </main>
  </body>
</html>
```

**Step 2: Write home page**

```erb
<%# app/views/pages/home.html.erb %>
<div class="home">
  <p class="home-tagline">Wordle, but with sounds.</p>
  <p class="home-description">
    Guess the word. Feedback is based on <strong>phonemes</strong> (IPA), not letters.
  </p>
  <div class="home-actions">
    <%= link_to "Daily Puzzle", daily_path, class: "btn btn-primary" %>
    <%= link_to "Practice", practice_path, class: "btn btn-secondary" %>
  </div>
</div>
```

**Step 3: Write game show view**

```erb
<%# app/views/games/show.html.erb %>
<div class="game-container" data-controller="game" data-game-id-value="<%= @game.id %>" data-game-url-value="<%= game_guesses_path(@game) %>" data-game-over-value="<%= @game.over? %>" data-game-max-guesses-value="6" data-game-current-guess-value="<%= @game.current_guess_number %>">

  <div id="error" class="error-container">
  </div>

  <div class="board">
    <% 6.times do |i| %>
      <% guess = (@game.guesses || [])[i] %>
      <%= render "games/row", guess: guess, row_index: i %>
    <% end %>
  </div>

  <% unless @game.over? %>
    <div class="input-row" data-game-target="inputRow">
      <input type="text"
             maxlength="20"
             autocomplete="off"
             autocapitalize="none"
             data-game-target="input"
             data-action="keydown.enter->game#submitGuess"
             placeholder="Type a word..."
             class="guess-input"
             autofocus>
      <button data-action="click->game#submitGuess" class="btn btn-submit">Enter</button>
    </div>
  <% end %>

  <% if @game.over? %>
    <div class="game-over">
      <% if @game.won? %>
        <p class="result-message result-win">You got it in <%= @game.current_guess_number %>!</p>
      <% else %>
        <p class="result-message result-loss">
          The word was <strong><%= @game.target_word.text %></strong>
          (<span class="ipa">/<%= @game.target_word.ipa %>/</span>)
        </p>
      <% end %>
      <% if @game.daily_puzzle %>
        <button data-controller="share"
                data-share-text-value="<%= share_text(@game) %>"
                data-action="click->share#copy"
                class="btn btn-primary">
          Share Result
        </button>
      <% end %>
      <% unless @game.daily_puzzle %>
        <%= link_to "Play Again", practice_path, class: "btn btn-primary" %>
      <% end %>
    </div>
  <% end %>
</div>
```

**Step 4: Write row partial**

```erb
<%# app/views/games/_row.html.erb %>
<div class="row" id="row-<%= row_index %>">
  <% if guess %>
    <% guess["phonemes"].each_with_index do |phoneme, i| %>
      <div class="cell cell-<%= guess["evaluation"][i] %>">
        <span class="ipa"><%= phoneme %></span>
      </div>
    <% end %>
  <% else %>
    <% 5.times do %>
      <div class="cell cell-empty">
        <span class="cell-letter" data-game-target="cell"></span>
      </div>
    <% end %>
  <% end %>
</div>
```

**Step 5: Write error partial**

```erb
<%# app/views/games/_error.html.erb %>
<div id="error" class="error-container">
  <% if local_assigns[:message] %>
    <p class="error-message"><%= message %></p>
  <% end %>
</div>
```

**Step 6: Write Turbo Stream response for guesses**

```erb
<%# app/views/guesses/create.turbo_stream.erb %>
<%= turbo_stream.replace "row-#{@guess_index}" do %>
  <%= render "games/row", guess: @guess_data, row_index: @guess_index %>
<% end %>

<%= turbo_stream.replace "error" do %>
  <%= render "games/error" %>
<% end %>

<% if @game.over? %>
  <%= turbo_stream.replace "game-input" do %>
    <div class="game-over">
      <% if @game.won? %>
        <p class="result-message result-win">You got it in <%= @game.current_guess_number %>!</p>
      <% else %>
        <p class="result-message result-loss">
          The word was <strong><%= @game.target_word.text %></strong>
          (<span class="ipa">/<%= @game.target_word.ipa %>/</span>)
        </p>
      <% end %>
    </div>
  <% end %>
<% end %>
```

**Step 7: Write share helper**

```ruby
# app/helpers/games_helper.rb
module GamesHelper
  def share_text(game)
    return "" unless game.over? && game.daily_puzzle

    guesses = game.guesses || []
    score = game.won? ? "#{guesses.length}/6" : "X/6"
    header = "Phonetic Wordle ##{game.daily_puzzle.puzzle_number} \xF0\x9F\x94\x8A #{score}\n\n"

    grid = guesses.map do |guess|
      guess["evaluation"].map do |e|
        case e
        when "correct" then "\u{1F7E9}"
        when "present" then "\u{1F7E8}"
        else "\u2B1B"
        end
      end.join
    end.join("\n")

    header + grid
  end
end
```

**Step 8: Write CSS**

```css
/* app/assets/stylesheets/application.css */
:root {
  --color-correct: #6aaa64;
  --color-present: #c9b458;
  --color-absent: #787c7e;
  --color-empty: #d3d6da;
  --color-bg: #ffffff;
  --color-text: #1a1a1b;
  --cell-size: 62px;
  --gap: 5px;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  background: var(--color-bg);
  color: var(--color-text);
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 100vh;
}

.header {
  width: 100%;
  text-align: center;
  padding: 12px 0;
  border-bottom: 1px solid var(--color-empty);
}

.header h1 {
  font-size: 1.6rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.header a {
  color: inherit;
  text-decoration: none;
}

.main {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
  width: 100%;
  max-width: 500px;
}

/* Home */
.home {
  text-align: center;
  padding: 40px 0;
}

.home-tagline {
  font-size: 1.4rem;
  font-weight: 600;
  margin-bottom: 12px;
}

.home-description {
  color: #555;
  margin-bottom: 24px;
  line-height: 1.5;
}

.home-actions {
  display: flex;
  gap: 12px;
  justify-content: center;
}

/* Buttons */
.btn {
  display: inline-block;
  padding: 12px 24px;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  text-decoration: none;
  text-align: center;
}

.btn-primary {
  background: var(--color-correct);
  color: white;
}

.btn-secondary {
  background: var(--color-absent);
  color: white;
}

.btn-submit {
  background: var(--color-text);
  color: white;
  padding: 10px 20px;
}

/* Game */
.game-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
  width: 100%;
}

.board {
  display: flex;
  flex-direction: column;
  gap: var(--gap);
}

.row {
  display: flex;
  gap: var(--gap);
}

.cell {
  width: var(--cell-size);
  height: var(--cell-size);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.3rem;
  font-weight: 700;
  border: 2px solid var(--color-empty);
  text-transform: none;
}

.cell .ipa {
  font-family: "Noto Sans", "DejaVu Sans", "Lucida Grande", sans-serif;
}

.cell-empty {
  background: transparent;
}

.cell-correct {
  background: var(--color-correct);
  border-color: var(--color-correct);
  color: white;
}

.cell-present {
  background: var(--color-present);
  border-color: var(--color-present);
  color: white;
}

.cell-absent {
  background: var(--color-absent);
  border-color: var(--color-absent);
  color: white;
}

/* Flip animation */
.cell-correct,
.cell-present,
.cell-absent {
  animation: flip 0.5s ease;
}

@keyframes flip {
  0% { transform: scaleY(1); }
  50% { transform: scaleY(0); }
  100% { transform: scaleY(1); }
}

/* Input */
.input-row {
  display: flex;
  gap: 8px;
  width: 100%;
  max-width: 330px;
}

.guess-input {
  flex: 1;
  padding: 10px 14px;
  font-size: 1.1rem;
  border: 2px solid var(--color-empty);
  border-radius: 4px;
  outline: none;
  text-transform: lowercase;
}

.guess-input:focus {
  border-color: var(--color-text);
}

/* Error */
.error-container {
  min-height: 28px;
}

.error-message {
  background: var(--color-text);
  color: white;
  padding: 8px 16px;
  border-radius: 4px;
  font-size: 0.9rem;
  font-weight: 600;
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-8px); }
  to { opacity: 1; transform: translateY(0); }
}

/* Game over */
.game-over {
  text-align: center;
  padding: 16px 0;
}

.result-message {
  font-size: 1.1rem;
  margin-bottom: 12px;
}

.result-win {
  font-weight: 700;
}

.result-loss {
  color: #555;
}

.ipa {
  font-style: italic;
}
```

**Step 9: Verify app boots and renders home page**

```bash
bin/rails server
```

Visit http://localhost:3000 — should see home page with "Wordle, but with sounds." and two buttons. Stop server.

**Step 10: Commit**

```bash
git add -A
git commit -m "feat: add views, layout, CSS, and game board"
```

---

### Task 9: Stimulus Controllers

**Files:**
- Create: `app/javascript/controllers/game_controller.js`
- Create: `app/javascript/controllers/share_controller.js`

**Step 1: Write game Stimulus controller**

```javascript
// app/javascript/controllers/game_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "cell", "inputRow"]
  static values = {
    id: Number,
    url: String,
    over: Boolean,
    maxGuesses: Number,
    currentGuess: Number
  }

  connect() {
    this.focusInput()
  }

  focusInput() {
    if (this.hasInputTarget && !this.overValue) {
      this.inputTarget.focus()
    }
  }

  async submitGuess() {
    if (this.overValue) return

    const input = this.inputTarget
    const guess = input.value.trim()
    if (!guess) return

    input.disabled = true

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
        },
        body: new URLSearchParams({ guess: guess })
      })

      const html = await response.text()
      Turbo.renderStreamMessage(html)

      input.value = ""
      this.currentGuessValue++

      if (this.currentGuessValue >= this.maxGuessesValue) {
        this.overValue = true
      }
    } catch (error) {
      console.error("Guess submission failed:", error)
    } finally {
      input.disabled = false
      this.focusInput()
    }
  }
}
```

**Step 2: Write share Stimulus controller**

```javascript
// app/javascript/controllers/share_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = "Share Result"
      }, 2000)
    } catch {
      // Fallback for older browsers
      const textarea = document.createElement("textarea")
      textarea.value = this.textValue
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)
      this.element.textContent = "Copied!"
      setTimeout(() => {
        this.element.textContent = "Share Result"
      }, 2000)
    }
  }
}
```

**Step 3: Verify controllers are registered**

Check that `app/javascript/controllers/index.js` auto-registers via stimulus-loading (Rails 8 default). If not, register manually:

```javascript
// app/javascript/controllers/index.js
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
```

**Step 4: Test in browser**

```bash
bin/rails db:seed  # if not already seeded
bin/rails server
```

Visit http://localhost:3000, click "Daily Puzzle", type a word, press Enter. Verify the row updates with IPA phonemes and colors.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add Stimulus controllers for game input and sharing"
```

---

### Task 10: On-Screen Keyboard

**Files:**
- Create: `app/javascript/controllers/keyboard_controller.js`
- Modify: `app/views/games/show.html.erb` (add keyboard markup)
- Modify: `app/assets/stylesheets/application.css` (add keyboard styles)

**Step 1: Add keyboard markup to game show view**

Add this after the input row in `app/views/games/show.html.erb`, inside the game-container div:

```erb
<div class="keyboard" data-controller="keyboard" data-keyboard-game-outlet=".game-container">
  <% %w[q w e r t y u i o p].each do |key| %>
    <button class="key" data-key="<%= key %>" data-action="click->keyboard#press"><%= key %></button>
  <% end %>
  <div class="keyboard-row">
    <% %w[a s d f g h j k l].each do |key| %>
      <button class="key" data-key="<%= key %>" data-action="click->keyboard#press"><%= key %></button>
    <% end %>
  </div>
  <div class="keyboard-row">
    <button class="key key-wide" data-action="click->keyboard#enter">Enter</button>
    <% %w[z x c v b n m].each do |key| %>
      <button class="key" data-key="<%= key %>" data-action="click->keyboard#press"><%= key %></button>
    <% end %>
    <button class="key key-wide" data-action="click->keyboard#backspace">⌫</button>
  </div>
</div>
```

**Step 2: Write keyboard controller**

```javascript
// app/javascript/controllers/keyboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  press(event) {
    const key = event.currentTarget.dataset.key
    const input = document.querySelector("[data-game-target='input']")
    if (input && !input.disabled) {
      input.value += key
      input.focus()
    }
  }

  enter() {
    const gameController = this.application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='game']"),
      "game"
    )
    if (gameController) {
      gameController.submitGuess()
    }
  }

  backspace() {
    const input = document.querySelector("[data-game-target='input']")
    if (input && !input.disabled) {
      input.value = input.value.slice(0, -1)
      input.focus()
    }
  }
}
```

**Step 3: Add keyboard CSS to application.css**

```css
/* Keyboard */
.keyboard {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  width: 100%;
  max-width: 500px;
  margin-top: 12px;
}

.keyboard-row {
  display: flex;
  gap: 6px;
}

/* First row is direct children buttons (not in a .keyboard-row) */
.keyboard > .key {
  display: inline-flex;
}

.keyboard > .key:first-child {
  margin-left: 0;
}

/* Wrap first row too */
.keyboard {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
}

.key {
  min-width: 32px;
  height: 52px;
  padding: 0 6px;
  border: none;
  border-radius: 4px;
  background: #d3d6da;
  font-size: 0.85rem;
  font-weight: 700;
  text-transform: uppercase;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.key:active {
  background: #b0b3b8;
}

.key-wide {
  min-width: 58px;
  font-size: 0.75rem;
}

.key-absent {
  background: var(--color-absent);
  color: white;
}
```

**Step 4: Test in browser**

```bash
bin/rails server
```

Verify on-screen keyboard types into input and Enter submits.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add on-screen keyboard with Stimulus controller"
```

---

### Task 11: End-to-End Polish and Testing

**Files:**
- Modify: `app/views/guesses/create.turbo_stream.erb` (handle game over in stream)
- Create: `test/system/game_play_test.rb`
- Modify: Various files for edge case fixes

**Step 1: Write system test**

```ruby
# test/system/game_play_test.rb
require "application_system_test_case"

class GamePlayTest < ApplicationSystemTestCase
  setup do
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    Word.create!(text: "bland", ipa: "blænd", phonemes: ["b", "l", "æ", "n", "d"], phoneme_count: 5)
    DailyPuzzle.create!(date: Date.current, word: Word.find_by(text: "plant"))
  end

  test "playing daily puzzle with a correct guess" do
    visit daily_path

    fill_in "Type a word...", with: "plant"
    click_button "Enter"

    assert_text "You got it in 1!"
  end

  test "playing daily puzzle with wrong guess then correct" do
    visit daily_path

    fill_in "Type a word...", with: "bland"
    click_button "Enter"

    # Should see the first row filled with IPA
    fill_in "Type a word...", with: "plant"
    click_button "Enter"

    assert_text "You got it in 2!"
  end

  test "invalid word shows error" do
    visit daily_path

    fill_in "Type a word...", with: "xyzzy"
    click_button "Enter"

    assert_text "Not in word list"
  end
end
```

**Step 2: Run system tests**

```bash
bin/rails test:system
```

Expected: All pass. Fix any issues discovered.

**Step 3: Run full test suite**

```bash
bin/rails test
```

Expected: All tests pass.

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add system tests for game play flow"
```

---

### Task 12: Update CLAUDE.md

**Step 1: Update CLAUDE.md with project conventions**

```markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Phonetic Wordle — a Wordle-style game where feedback is based on phonemes (IPA) instead of letters. Players type English words, which are converted to IPA via the CMU Pronouncing Dictionary.

## Commands

- `bin/rails server` — start dev server
- `bin/rails test` — run all tests
- `bin/rails test test/path/to/test.rb` — run single test file
- `bin/rails test test/path/to/test.rb:LINE` — run single test
- `bin/rails test:system` — run Capybara system tests
- `bin/rails db:seed` — seed words from CMU dictionary (required before first run)
- `bin/rails db:migrate` — run pending migrations

## Architecture

Rails 8 app, fully server-rendered with Turbo Streams and Stimulus. No SPA, no Node, no Tailwind.

### Key services (app/services/)
- **ArpabetToIpa** — converts ARPAbet phoneme notation to IPA symbols
- **CmuDictParser** — parses CMU dictionary file into Word model attributes
- **GuessValidator** — validates a guess exists in dictionary and has exactly 5 phonemes
- **GuessEvaluator** — implements Wordle's matching algorithm on phoneme arrays (exact match first, then present/absent)

### Stimulus controllers (app/javascript/controllers/)
- **game_controller** — handles text input and guess submission via Turbo Stream
- **keyboard_controller** — on-screen QWERTY keyboard
- **share_controller** — copies emoji result grid to clipboard

### Game flow
1. Player types English word → POST to GuessesController
2. Server validates (GuessValidator) → evaluates (GuessEvaluator)
3. Turbo Stream replaces grid row with IPA phonemes + color coding
4. Game state tracked in Game model, tied to browser session

### Data
- Words seeded from CMU Pronouncing Dictionary (db/cmu_dict/), filtered to 5-phoneme words only
- DailyPuzzle assigns one word per calendar date
- Game stores guesses as JSON array with phonemes and evaluation results
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: update CLAUDE.md with project architecture"
```

---

Plan complete and saved to `docs/plans/2026-03-17-phonetic-wordle-implementation.md`. Two execution options:

**1. Subagent-Driven (this session)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** — Open new session with executing-plans, batch execution with checkpoints

Which approach?