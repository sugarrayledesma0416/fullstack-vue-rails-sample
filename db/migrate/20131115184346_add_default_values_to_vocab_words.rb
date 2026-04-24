class AddDefaultValuesToVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    change_column :vocab_words, :target_word, :string, :default => ""
    change_column :vocab_words, :target_definition, :string, :default => ""
    change_column :vocab_words, :base_word, :string, :default => ""

    change_column :default_vocab_words, :target_word, :string, :default => ''
    change_column :default_vocab_words, :target_definition, :string, :default => ''
    change_column :default_vocab_words, :base_word, :string, :default => ''
  end

  def self.down
    change_column :vocab_words, :target_word, :string
    change_column :vocab_words, :target_definition, :string
    change_column :vocab_words, :base_word, :string
  end
end
