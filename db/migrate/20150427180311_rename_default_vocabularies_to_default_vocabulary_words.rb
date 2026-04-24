class RenameDefaultVocabulariesToDefaultVocabularyWords < ActiveRecord::Migration[4.2]
  def up
    rename_table :default_vocabularies, :default_vocabulary_words
  end

  def down
    rename_table :default_vocabulary_words, :default_vocabularies
  end
end
