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
    find(".btn-submit").click

    assert_text "You got it in 1!"
  end

  test "playing daily puzzle with wrong guess then correct" do
    visit daily_path

    fill_in "Type a word...", with: "bland"
    find(".btn-submit").click

    # Wait for the first guess to be processed
    assert_selector ".cell-correct, .cell-present, .cell-absent", wait: 5

    fill_in "Type a word...", with: "plant"
    find(".btn-submit").click

    assert_text "You got it in 2!"
  end

  test "invalid word shows error" do
    visit daily_path

    fill_in "Type a word...", with: "xyzzy"
    find(".btn-submit").click

    assert_text "Not in word list"
  end
end
