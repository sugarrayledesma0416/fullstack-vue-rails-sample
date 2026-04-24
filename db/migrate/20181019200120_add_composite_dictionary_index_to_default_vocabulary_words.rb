class AddCompositeDictionaryIndexToDefaultVocabularyWords < ActiveRecord::Migration[4.2]
  def change
    add_index :default_vocabulary_words, [:composite_dictionary_id], name: 'idx_default_vocabulary_words_composite_dictionary'
  end
end
