class CreateWords < ActiveRecord::Migration[8.1]
  def change
    create_table :words do |t|
      t.string :text, null: false
      t.string :ipa, null: false
      t.json :phonemes, null: false
      t.integer :phoneme_count, null: false

      t.timestamps
    end

    add_index :words, :text, unique: true
    add_index :words, :phoneme_count
  end
end
