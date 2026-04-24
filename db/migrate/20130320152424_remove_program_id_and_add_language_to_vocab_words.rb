class RemoveProgramIdAndAddLanguageToVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :vocab_words, :program_id
    add_column :vocab_words, :language, :string
  end

  def self.down
    add_column :vocab_words, :program_id, :integer
    remove_column :vocab_words, :language
  end
end
