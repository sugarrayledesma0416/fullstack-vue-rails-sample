class AddLessonIdToDefaultVocabWordsAndVocabWords < ActiveRecord::Migration[4.2]
  def self.up
    add_column :vocab_words, :lesson_id, :integer
    add_column :default_vocab_words, :lesson_id, :integer
  end

  def self.down
    remove_column :vocab_words, :lesson_id
    remove_column :default_vocab_words, :lesson_id
  end
end
