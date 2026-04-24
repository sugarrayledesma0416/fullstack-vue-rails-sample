class AddChineseFieldsToUnits < ActiveRecord::Migration[5.2]
  def change
    add_column :units, :english_title, :string
    add_column :units, :chinese_title, :string
    add_column :units, :pinyin_title, :string
  end
end
