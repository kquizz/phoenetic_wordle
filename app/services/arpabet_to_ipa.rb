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

  def self.convert(arpabet)
    base = arpabet.gsub(/[012]$/, "")
    MAPPING.fetch(base) { raise UnknownPhoneme, "Unknown ARPAbet phoneme: #{arpabet}" }
  end

  def self.convert_sequence(arpabet_phonemes)
    arpabet_phonemes.map { |p| convert(p) }
  end
end
