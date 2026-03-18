class CreateDailyPuzzles < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_puzzles do |t|
      t.date :date, null: false
      t.references :word, null: false, foreign_key: true
      t.timestamps
    end
    add_index :daily_puzzles, :date, unique: true
  end
end
