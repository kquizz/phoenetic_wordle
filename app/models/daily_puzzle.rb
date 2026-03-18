class DailyPuzzle < ApplicationRecord
  belongs_to :word

  validates :date, presence: true, uniqueness: true

  def self.for_today
    today = Date.current
    find_or_create_by!(date: today) do |puzzle|
      puzzle.word = Word.five_phonemes.order("RANDOM()").first!
    end
  end

  def puzzle_number
    (date - Date.new(2026, 1, 1)).to_i
  end
end
