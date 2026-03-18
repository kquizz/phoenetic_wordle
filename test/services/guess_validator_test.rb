require "test_helper"

class GuessValidatorTest < ActiveSupport::TestCase
  setup do
    Word.create!(text: "plant", ipa: "plænt", phonemes: ["p", "l", "æ", "n", "t"], phoneme_count: 5)
    Word.create!(text: "cat", ipa: "kæt", phonemes: ["k", "æ", "t"], phoneme_count: 3)
  end

  test "valid word with matching phoneme count returns success" do
    result = GuessValidator.validate("plant", expected_phoneme_count: 5)
    assert result.valid?
    assert_equal ["p", "l", "æ", "n", "t"], result.phonemes
  end

  test "valid 3-phoneme word with default count returns success" do
    result = GuessValidator.validate("cat")
    assert result.valid?
    assert_equal ["k", "æ", "t"], result.phonemes
  end

  test "word not in dictionary returns error" do
    result = GuessValidator.validate("xyzzy")
    assert_not result.valid?
    assert_equal :not_in_dictionary, result.error
  end

  test "word with wrong phoneme count returns error" do
    result = GuessValidator.validate("plant", expected_phoneme_count: 3)
    assert_not result.valid?
    assert_equal :wrong_phoneme_count, result.error
    assert_equal 5, result.phoneme_count
  end

  test "normalizes input to lowercase" do
    result = GuessValidator.validate("CAT")
    assert result.valid?
  end

  test "rejects blank input" do
    result = GuessValidator.validate("")
    assert_not result.valid?
    assert_equal :blank, result.error
  end
end
