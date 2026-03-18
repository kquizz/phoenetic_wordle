class GuessValidator
  Result = Struct.new(:valid?, :error, :phonemes, :phoneme_count, :word, keyword_init: true)

  def self.validate(input, expected_phoneme_count: Word::DEFAULT_PHONEME_COUNT)
    text = input.to_s.strip.downcase

    if text.empty?
      return Result.new(valid?: false, error: :blank)
    end

    word = Word.find_by(text: text)

    unless word
      return Result.new(valid?: false, error: :not_in_dictionary)
    end

    unless word.phoneme_count == expected_phoneme_count
      return Result.new(valid?: false, error: :wrong_phoneme_count, phoneme_count: word.phoneme_count, phonemes: word.phonemes, word: word)
    end

    Result.new(valid?: true, phonemes: word.phonemes, word: word)
  end
end
