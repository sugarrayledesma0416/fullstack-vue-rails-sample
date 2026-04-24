class AddVocabWordIdIndexToVocabTags < ActiveRecord::Migration[4.2]
  def change
    add_index :vocab_tags, :vocab_word_id, name: 'by_vocab_word'
  end
end
