class CreateVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    create_table :vocab_words do |t|
      t.references :user
      t.references :program
      t.string :target_word, :base_word, :target_definition
      t.timestamps
    end
  end

  def self.down
    drop_table :vocab_words
  end
end
