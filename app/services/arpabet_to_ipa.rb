class ArpabetToIpa
  class UnknownPhoneme < StandardError; end

  MAPPING = {
    "AA" => "ɑ",
    "AE" => "æ",
    "AH" => "ʌ",
    "AO" => "ɔ",
    "EH" => "ɛ",
    "ER" => "ɝ",
    "IH" => "ɪ",
    "IY" => "i",
    "UH" => "ʊ",
    "UW" => "u",
    "AW" => "aʊ",
    "AY" => "aɪ",
    "EY" => "eɪ",
    "OW" => "oʊ",
    "OY" => "ɔɪ",
    "B"  => "b",
    "CH" => "tʃ",
    "D"  => "d",
    "DH" => "ð",
    "F"  => "f",
    "G"  => "ɡ",
    "HH" => "h",
    "JH" => "dʒ",
    "K"  => "k",
    "L"  => "l",
    "M"  => "m",
    "N"  => "n",
    "NG" => "ŋ",
    "P"  => "p",
    "R"  => "ɹ",
    "S"  => "s",
    "SH" => "ʃ",
    "T"  => "t",
    "TH" => "θ",
    "V"  => "v",
    "W"  => "w",
    "Y"  => "j",
    "Z"  => "z",
    "ZH" => "ʒ"
  }.freeze

  # Friendly English descriptions for each IPA symbol
  FRIENDLY = {
    "ɑ" => "ah (odd)",
    "æ" => "a (cat)",
    "ʌ" => "uh (hut)",
    "ɔ" => "aw (ought)",
    "ɛ" => "eh (bed)",
    "ɝ" => "er (hurt)",
    "ɪ" => "ih (bit)",
    "i" => "ee (eat)",
    "ʊ" => "oo (hood)",
    "u" => "oo (two)",
    "aʊ" => "ow (cow)",
    "aɪ" => "eye (my)",
    "eɪ" => "ay (ate)",
    "oʊ" => "oh (oat)",
    "ɔɪ" => "oy (toy)",
    "b" => "b (boy)",
    "tʃ" => "ch (chair)",
    "d" => "d (dog)",
    "ð" => "th (the)",
    "f" => "f (fish)",
    "ɡ" => "g (go)",
    "h" => "h (hat)",
    "dʒ" => "j (judge)",
    "k" => "k (cat)",
    "l" => "l (lip)",
    "m" => "m (man)",
    "n" => "n (no)",
    "ŋ" => "ng (sing)",
    "p" => "p (pat)",
    "ɹ" => "r (red)",
    "s" => "s (sit)",
    "ʃ" => "sh (she)",
    "t" => "t (top)",
    "θ" => "th (think)",
    "v" => "v (van)",
    "w" => "w (win)",
    "j" => "y (yes)",
    "z" => "z (zoo)",
    "ʒ" => "zh (measure)"
  }.freeze

  def self.friendly(ipa_symbol)
    FRIENDLY[ipa_symbol] || ipa_symbol
  end

  def self.convert(arpabet)
    base = arpabet.gsub(/[012]$/, "")
    MAPPING.fetch(base) { raise UnknownPhoneme, "Unknown ARPAbet phoneme: #{arpabet}" }
  end

  def self.convert_sequence(arpabet_phonemes)
    arpabet_phonemes.map { |p| convert(p) }
  end
end
