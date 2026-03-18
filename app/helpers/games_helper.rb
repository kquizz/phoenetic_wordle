module GamesHelper
  def share_text(game)
    return "" unless game.over? && game.daily_puzzle

    guesses = game.guesses || []
    score = game.won? ? "#{guesses.length}/6" : "X/6"
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
end
