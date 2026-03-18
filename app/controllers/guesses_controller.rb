class GuessesController < ApplicationController
  def create
    @game = Game.find(params[:game_id])
    @guess_text = params[:guess].to_s.strip.downcase

    if @game.over?
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("error", partial: "games/error", locals: { message: "Game is already over" }) }
      end
      return
    end

    validation = GuessValidator.validate(@guess_text)

    unless validation.valid?
      message = case validation.error
                when :blank then "Please enter a word"
                when :not_in_dictionary then "Not in word list"
                when :wrong_phoneme_count then "That word has #{validation.phoneme_count} sounds, you need 5"
                end

      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("error", partial: "games/error", locals: { message: message }) }
      end
      return
    end

    evaluation = GuessEvaluator.evaluate(
      guess: validation.phonemes,
      target: @game.target_word.phonemes
    )

    @game.add_guess!(@guess_text, validation.phonemes, evaluation.map(&:to_s))
    @guess_index = @game.current_guess_number - 1
    @guess_data = @game.guesses[@guess_index]

    respond_to do |format|
      format.turbo_stream
    end
  end
end
