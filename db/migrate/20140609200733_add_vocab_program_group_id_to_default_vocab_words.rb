class AddVocabProgramGroupIdToDefaultVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    add_column :default_vocab_words, :vocab_program_group_id, :integer
  end

  def self.down
    remove_column :default_vocab_words, :vocab_program_group_id
  end
end
