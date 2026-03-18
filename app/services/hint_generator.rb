class HintGenerator
  # Returns up to 5 words that are still possible given the game's guesses so far
  def self.suggestions(game, limit: 5)
    return [] if game.over?

    constraints = build_constraints(game)
    candidates = Word.with_phoneme_count(game.phoneme_count)

    candidates.select { |word| matches_constraints?(word.phonemes, constraints) }
              .sample(limit)
              .map(&:text)
  end

  private

  def self.build_constraints(game)
    correct = {}       # position => phoneme (must be this)
    present = {}       # phoneme => Set of positions where it's NOT (but it IS somewhere)
    absent = Set.new   # phonemes that are completely absent

    (game.guesses || []).each do |guess|
      phonemes = guess["phonemes"]
      evaluation = guess["evaluation"]

      phonemes.each_with_index do |phoneme, i|
        case evaluation[i]
        when "correct"
          correct[i] = phoneme
        when "present"
          present[phoneme] ||= Set.new
          present[phoneme] << i
        when "absent"
          # Only mark absent if this phoneme isn't correct/present elsewhere
          unless correct.values.include?(phoneme) || present.key?(phoneme)
            absent << phoneme
          end
        end
      end
    end

    { correct: correct, present: present, absent: absent }
  end

  def self.matches_constraints?(phonemes, constraints)
    # Check correct positions
    constraints[:correct].each do |pos, phoneme|
      return false unless phonemes[pos] == phoneme
    end

    # Check present phonemes (must exist but not at known wrong positions)
    constraints[:present].each do |phoneme, wrong_positions|
      return false unless phonemes.include?(phoneme)
      wrong_positions.each do |pos|
        return false if phonemes[pos] == phoneme
      end
    end

    # Check absent phonemes
    constraints[:absent].each do |phoneme|
      return false if phonemes.include?(phoneme)
    end

    true
  end
end
