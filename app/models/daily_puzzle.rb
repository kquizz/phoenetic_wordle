class DailyPuzzle < ApplicationRecord
  belongs_to :word

  validates :date, presence: true, uniqueness: { scope: :phoneme_count }
  validates :phoneme_count, presence: true

  def self.for_today(phoneme_count: Word::DEFAULT_PHONEME_COUNT)
    today = Date.current
    find_or_create_by!(date: today, phoneme_count: phoneme_count) do |puzzle|
      puzzle.word = Word.with_phoneme_count(phoneme_count).order("RANDOM()").first!
    end
  end

  def puzzle_number
    (date - Date.new(2026, 1, 1)).to_i
  end
end
