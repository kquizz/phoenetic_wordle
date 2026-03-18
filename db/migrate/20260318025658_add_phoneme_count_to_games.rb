class AddPhonemeCountToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :phoneme_count, :integer, null: false, default: 3
  end
end
