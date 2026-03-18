require "test_helper"

class DailyPuzzleTest < ActiveSupport::TestCase
  setup do
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3, common: true)
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5, common: true)
  end

  test "for_today creates puzzle for today with default phoneme count" do
    puzzle = DailyPuzzle.for_today
    assert_equal Date.current, puzzle.date
    assert_equal 3, puzzle.phoneme_count
    assert_equal "cat", puzzle.word.text
  end

  test "for_today with specific phoneme count" do
    puzzle = DailyPuzzle.for_today(phoneme_count: 5)
    assert_equal 5, puzzle.phoneme_count
    assert_equal "plant", puzzle.word.text
  end

  test "for_today returns same puzzle on second call" do
    puzzle1 = DailyPuzzle.for_today
    puzzle2 = DailyPuzzle.for_today
    assert_equal puzzle1.id, puzzle2.id
  end

  test "different phoneme counts get different daily puzzles" do
    puzzle3 = DailyPuzzle.for_today(phoneme_count: 3)
    puzzle5 = DailyPuzzle.for_today(phoneme_count: 5)
    assert_not_equal puzzle3.id, puzzle5.id
  end

  test "puzzle_number counts days from epoch" do
    puzzle = DailyPuzzle.create!(date: Date.new(2026, 1, 11), word: Word.first, phoneme_count: 3)
    assert_equal 10, puzzle.puzzle_number
  end
end
