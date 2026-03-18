# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_18_025757) do
  create_table "daily_puzzles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "phoneme_count", default: 3, null: false
    t.datetime "updated_at", null: false
    t.integer "word_id", null: false
    t.index ["date", "phoneme_count"], name: "index_daily_puzzles_on_date_and_phoneme_count", unique: true
    t.index ["word_id"], name: "index_daily_puzzles_on_word_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "daily_puzzle_id"
    t.json "guesses", default: "[]", null: false
    t.integer "phoneme_count", default: 3, null: false
    t.string "session_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "target_word_id", null: false
    t.datetime "updated_at", null: false
    t.index ["daily_puzzle_id"], name: "index_games_on_daily_puzzle_id"
    t.index ["session_id", "daily_puzzle_id"], name: "index_games_on_session_id_and_daily_puzzle_id", unique: true
    t.index ["target_word_id"], name: "index_games_on_target_word_id"
  end

  create_table "words", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ipa", null: false
    t.integer "phoneme_count", null: false
    t.json "phonemes", null: false
    t.string "text", null: false
    t.datetime "updated_at", null: false
    t.index ["phoneme_count"], name: "index_words_on_phoneme_count"
    t.index ["text"], name: "index_words_on_text", unique: true
  end

  add_foreign_key "daily_puzzles", "words"
  add_foreign_key "games", "daily_puzzles"
  add_foreign_key "games", "words", column: "target_word_id"
end
