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
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:present, :correct, :present, :present, :present], result
  end

  test "duplicate phoneme in guess — one correct, one absent" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["p", "p", "æ", "n", "t"]
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:correct, :absent, :correct, :correct, :correct], result
  end

  test "duplicate phoneme in guess — one present, one absent" do
    target  = ["p", "l", "æ", "n", "t"]
    guess   = ["b", "p", "æ", "p", "t"]
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:absent, :present, :correct, :absent, :correct], result
  end

  test "duplicate phoneme in target" do
    target  = ["p", "æ", "p", "æ", "t"]
    guess   = ["p", "b", "b", "æ", "t"]
    result = GuessEvaluator.evaluate(guess: guess, target: target)
    assert_equal [:correct, :absent, :absent, :correct, :correct], result
  end
end
