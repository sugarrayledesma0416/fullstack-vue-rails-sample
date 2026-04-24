class AddPinyinToDefaultVocabularyWords < ActiveRecord::Migration[5.2]
  def change
    add_column :default_vocabulary_words, :pinyin, :string
  end
end
