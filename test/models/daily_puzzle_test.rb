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
