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
