class GamesController < ApplicationController
  def daily
    @phoneme_count = validated_phoneme_count
    puzzle = DailyPuzzle.for_today(phoneme_count: @phoneme_count)
    @game = Game.find_or_create_by!(session_id: current_session_id, daily_puzzle: puzzle) do |game|
      game.target_word = puzzle.word
      game.phoneme_count = @phoneme_count
    end
    render :show
  end

  def practice
    @phoneme_count = validated_phoneme_count
    @game = Game.create!(
      session_id: current_session_id,
      target_word: Word.with_phoneme_count(@phoneme_count).order("RANDOM()").first!,
      phoneme_count: @phoneme_count
    )
    render :show
  end

  private

  def validated_phoneme_count
    count = (params[:phonemes] || Word::DEFAULT_PHONEME_COUNT).to_i
    Word::ALLOWED_PHONEME_COUNTS.include?(count) ? count : Word::DEFAULT_PHONEME_COUNT
  end
end
