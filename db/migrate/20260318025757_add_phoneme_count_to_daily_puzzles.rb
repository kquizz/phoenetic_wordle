class AddPhonemeCountToDailyPuzzles < ActiveRecord::Migration[8.1]
  def change
    add_column :daily_puzzles, :phoneme_count, :integer, null: false, default: 3
    remove_index :daily_puzzles, :date
    add_index :daily_puzzles, [:date, :phoneme_count], unique: true
  end
end
