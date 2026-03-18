class AddCommonToWords < ActiveRecord::Migration[8.1]
  def change
    add_column :words, :common, :boolean, null: false, default: false
    add_index :words, [:phoneme_count, :common]
  end
end
