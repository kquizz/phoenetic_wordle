require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @target = Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    @game = Game.create!(session_id: "test-session", target_word: @target)
  end

  test "starts in_progress with empty guesses" do
    assert @game.in_progress?
    assert_equal 0, @game.current_guess_number
    assert_equal Game::MAX_GUESSES, @game.guesses_remaining
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

  test "game is lost after max incorrect guesses" do
    Game::MAX_GUESSES.times do |i|
      @game.add_guess!("wrong#{i}", ["b", "ɹ", "ɪ", "ŋ", "k"], ["absent", "absent", "absent", "absent", "absent"])
    end
    assert @game.lost?
    assert @game.over?
  end

  test "guesses_remaining decrements" do
    @game.add_guess!("crane", ["k", "ɹ", "eɪ", "n", "t"], ["absent", "absent", "absent", "correct", "correct"])
    assert_equal Game::MAX_GUESSES - 1, @game.guesses_remaining
  end
end
