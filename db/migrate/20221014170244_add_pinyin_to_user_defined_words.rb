class AddPinyinToUserDefinedWords < ActiveRecord::Migration[5.2]
  def change
    add_column :user_defined_words, :pinyin, :string
  end
end
