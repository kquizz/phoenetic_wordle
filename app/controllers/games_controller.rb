class GamesController < ApplicationController
  def daily
    puzzle = DailyPuzzle.for_today
    @game = Game.find_or_create_by!(session_id: current_session_id, daily_puzzle: puzzle) do |game|
      game.target_word = puzzle.word
    end
    render :show
  end

  def practice
    @game = Game.create!(
      session_id: current_session_id,
      target_word: Word.five_phonemes.order("RANDOM()").first!
    )
    render :show
  end
end
