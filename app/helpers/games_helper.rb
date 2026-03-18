module GamesHelper
  def share_text(game)
    return "" unless game.over? && game.daily_puzzle

    guesses = game.guesses || []
    score = game.won? ? "#{guesses.length}/#{Game::MAX_GUESSES}" : "X/#{Game::MAX_GUESSES}"
    header = "Phonetic Wordle ##{game.daily_puzzle.puzzle_number} \xF0\x9F\x94\x8A #{score}\n\n"

    grid = guesses.map do |guess|
      guess["evaluation"].map do |e|
        case e
        when "correct" then "\u{1F7E9}"
        when "present" then "\u{1F7E8}"
        else "\u2B1B"
        end
      end.join
    end.join("\n")

    header + grid
  end

  # Build a hash of phoneme => best status from all guesses so far
  # Priority: correct > present > absent > unused
  def phoneme_keyboard_states(game)
    states = {}
    priority = { "correct" => 3, "present" => 2, "absent" => 1 }

    (game.guesses || []).each do |guess|
      guess["phonemes"].each_with_index do |phoneme, i|
        eval_status = guess["evaluation"][i]
        current_priority = priority[states[phoneme]] || 0
        new_priority = priority[eval_status] || 0
        states[phoneme] = eval_status if new_priority > current_priority
      end
    end

    states
  end

  # All IPA phonemes grouped for keyboard layout
  IPA_KEYBOARD_LAYOUT = {
    "Consonants" => %w[p b t d k ɡ f v θ ð s z ʃ ʒ h tʃ dʒ m n ŋ l ɹ w j],
    "Vowels" => %w[i ɪ ɛ æ ɑ ɔ ʊ u ʌ ɝ],
    "Diphthongs" => %w[eɪ aɪ ɔɪ oʊ aʊ]
  }.freeze
end
