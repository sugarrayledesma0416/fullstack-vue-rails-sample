class CreateDefaultVocabTags < ActiveRecord::Migration[4.2]
  def self.up
    create_table :default_vocab_tags do |t|
      t.string :name
      t.integer :default_vocab_word_id

      t.timestamps
    end
  end

  def self.down
    drop_table :default_vocab_tags
  end
end
