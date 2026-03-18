class Game < ApplicationRecord
  belongs_to :daily_puzzle, optional: true
  belongs_to :target_word, class_name: "Word"

  attribute :guesses, default: -> { [] }

  enum :status, { in_progress: 0, won: 1, lost: 2 }

  MAX_GUESSES = 8

  validates :session_id, presence: true
  validates :status, presence: true
  validates :phoneme_count, presence: true

  def add_guess!(word_text, phonemes, evaluation)
    guesses_array = guesses || []
    guesses_array << {
      word: word_text,
      phonemes: phonemes,
      evaluation: evaluation
    }
    self.guesses = guesses_array

    if evaluation.all? { |e| e == "correct" }
      self.status = :won
      self.completed_at = Time.current
    elsif guesses_array.length >= MAX_GUESSES
      self.status = :lost
      self.completed_at = Time.current
    end

    save!
  end

  def current_guess_number
    (guesses || []).length
  end

  def over?
    won? || lost?
  end

  def guesses_remaining
    MAX_GUESSES - current_guess_number
  end
end
