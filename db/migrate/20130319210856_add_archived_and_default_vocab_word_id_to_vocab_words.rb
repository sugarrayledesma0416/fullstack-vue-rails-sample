class AddArchivedAndDefaultVocabWordIdToVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    add_column :vocab_words, :archived, :boolean, :default => false, :null => false
    add_column :vocab_words, :default_vocab_word_id, :integer
  end

  def self.down
    remove_column :vocab_words, :archived
    remove_column :vocab_words, :default_vocab_word_id
  end
end
