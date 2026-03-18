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
