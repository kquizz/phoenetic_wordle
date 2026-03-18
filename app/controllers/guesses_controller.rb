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

    # Handle hint request
    if @guess_text == "?"
      hints = HintGenerator.suggestions(@game)
      message = hints.any? ? "Try: #{hints.join(', ')}" : "No suggestions available"
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("error", partial: "games/error", locals: { message: message, auto_dismiss: true }) }
      end
      return
    end

    validation = GuessValidator.validate(@guess_text, expected_phoneme_count: @game.phoneme_count)

    unless validation.valid?
      message = case validation.error
                when :blank then "Please enter a word"
                when :not_in_dictionary then "Not in word list"
                when :wrong_phoneme_count then "\"#{@guess_text}\" is #{validation.phoneme_count} phonemes: #{validation.phonemes.join(' · ')} — needs #{@game.phoneme_count}"
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
