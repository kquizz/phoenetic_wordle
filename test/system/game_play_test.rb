require "application_system_test_case"

class GamePlayTest < ApplicationSystemTestCase
  setup do
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3)
    Word.create!(text: "bat", ipa: "bæt", phonemes: ["b", "æ", "t"], phoneme_count: 3)
    DailyPuzzle.create!(date: Date.current, word: Word.find_by(text: "cat"), phoneme_count: 3)
  end

  test "playing daily puzzle with a correct guess" do
    visit daily_path

    fill_in "guess", with: "cat"
    find(".btn-submit").click

    assert_text "You got it in 1!", wait: 5
  end

  test "playing daily puzzle with wrong guess then correct" do
    visit daily_path

    fill_in "guess", with: "bat"
    find(".btn-submit").click

    # Wait for the first row to be evaluated
    assert_selector ".cell-correct, .cell-present, .cell-absent", wait: 5

    # Wait for the new form to appear
    assert_selector ".guess-input", wait: 5

    fill_in "guess", with: "cat"
    find(".btn-submit").click

    assert_text "You got it in 2!", wait: 5
  end

  test "invalid word shows error" do
    visit daily_path

    fill_in "guess", with: "xyzzy"
    find(".btn-submit").click

    assert_text "Not in word list", wait: 5
  end
end
