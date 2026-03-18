class GuessValidator
  Result = Struct.new(:valid?, :error, :phonemes, :phoneme_count, :word, keyword_init: true)

  def self.validate(input)
    text = input.to_s.strip.downcase

    if text.empty?
      return Result.new(valid?: false, error: :blank)
    end

    word = Word.find_by(text: text)

    unless word
      return Result.new(valid?: false, error: :not_in_dictionary)
    end

    unless word.phoneme_count == 5
      return Result.new(valid?: false, error: :wrong_phoneme_count, phoneme_count: word.phoneme_count)
    end

    Result.new(valid?: true, phonemes: word.phonemes, word: word)
  end
end
