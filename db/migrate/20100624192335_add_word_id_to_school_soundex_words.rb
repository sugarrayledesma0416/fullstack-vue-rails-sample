class AddWordIdToSchoolSoundexWords < ActiveRecord::Migration[4.2]
  def self.up
    add_column :school_soundex_words, :word_id, :integer, :null => false
  end

  def self.down
    remove_column :school_soundex_words, :word_id
  end
end
