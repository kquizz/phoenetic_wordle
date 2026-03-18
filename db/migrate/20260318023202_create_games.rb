class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.references :daily_puzzle, null: true, foreign_key: true
      t.string :session_id, null: false
      t.references :target_word, null: false, foreign_key: { to_table: :words }
      t.json :guesses, null: false, default: "[]"
      t.integer :status, null: false, default: 0
      t.datetime :completed_at
      t.timestamps
    end
    add_index :games, [:session_id, :daily_puzzle_id], unique: true
  end
end
