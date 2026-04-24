class AddUserIdAndDefaultVocabWordIdIndexOnVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    add_index :vocab_words, [:user_id, :default_vocab_word_id], :name => 'by_user_and_default_vocab_word'
  end

  def self.down
    remove_index :vocab_words, 'by_user_and_default_vocab_word'
  end
end
