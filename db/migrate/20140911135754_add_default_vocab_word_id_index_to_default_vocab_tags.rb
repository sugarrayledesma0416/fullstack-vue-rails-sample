class AddDefaultVocabWordIdIndexToDefaultVocabTags < ActiveRecord::Migration[4.2]
  def change
    add_index :default_vocab_tags, :default_vocab_word_id, name: 'by_default_vocab_word'
  end
end
