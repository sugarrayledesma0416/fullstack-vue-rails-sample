class CreateDefaultVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    create_table :default_vocab_words do |t|
      t.references :program
      t.string :target_word, :base_word, :target_definition, :language
      t.timestamps
    end
  end

  def self.down
    drop_table :default_vocab_words
  end
end
