class GuessEvaluator
  def self.evaluate(guess:, target:)
    result = Array.new(5, :absent)
    target_remaining = target.dup

    # Pass 1: Mark exact matches (correct)
    guess.each_with_index do |phoneme, i|
      if phoneme == target[i]
        result[i] = :correct
        target_remaining[i] = nil
      end
    end

    # Pass 2: Mark present (right phoneme, wrong position)
    guess.each_with_index do |phoneme, i|
      next if result[i] == :correct

      match_index = target_remaining.index(phoneme)
      if match_index
        result[i] = :present
        target_remaining[match_index] = nil
      end
    end

    result
  end
end
