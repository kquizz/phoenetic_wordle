class CmuDictParser
  def self.parse_line(line)
    line = line.split("#").first.to_s.strip
    return nil if line.start_with?(";;;") || line.empty?
    return nil if line.match?(/\(\d+\)/)

    parts = line.split(/\s+/)
    word = parts[0].downcase
    arpabet = parts[1..]

    { word: word, arpabet: arpabet }
  end

  def self.line_to_word_attrs(line)
    parsed = parse_line(line)
    return nil unless parsed

    ipa_phonemes = ArpabetToIpa.convert_sequence(parsed[:arpabet])

    {
      text: parsed[:word],
      phonemes: ipa_phonemes,
      ipa: ipa_phonemes.join,
      phoneme_count: ipa_phonemes.length
    }
  end

  def self.parse_file(path)
    File.foreach(path) do |line|
      attrs = line_to_word_attrs(line)
      next unless attrs
      yield attrs
    end
  end
end
