require "test_helper"

class CmuDictParserTest < ActiveSupport::TestCase
  test "parses a line into word and arpabet phonemes" do
    line = "night N AY1 T"
    result = CmuDictParser.parse_line(line)
    assert_equal "night", result[:word]
    assert_equal ["N", "AY1", "T"], result[:arpabet]
  end

  test "skips comment lines" do
    line = ";;; this is a comment"
    assert_nil CmuDictParser.parse_line(line)
  end

  test "handles alternate pronunciations like word(2)" do
    line = "read(2) R EH1 D"
    result = CmuDictParser.parse_line(line)
    assert_nil result
  end

  test "strips inline comments" do
    line = "aalborg AO1 L B AO0 R G # place, danish"
    result = CmuDictParser.parse_line(line)
    assert_equal "aalborg", result[:word]
    assert_equal ["AO1", "L", "B", "AO0", "R", "G"], result[:arpabet]
  end

  test "builds word attributes from parsed line" do
    line = "night N AY1 T"
    attrs = CmuDictParser.line_to_word_attrs(line)
    assert_equal "night", attrs[:text]
    assert_equal ["n", "aɪ", "t"], attrs[:phonemes]
    assert_equal "naɪt", attrs[:ipa]
    assert_equal 3, attrs[:phoneme_count]
  end
end
