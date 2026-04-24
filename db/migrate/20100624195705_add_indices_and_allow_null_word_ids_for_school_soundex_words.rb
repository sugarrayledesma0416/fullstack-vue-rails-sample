class AddIndicesAndAllowNullWordIdsForSchoolSoundexWords < ActiveRecord::Migration[4.2]
  def self.up
    add_index     :school_soundex_words, :soundex
    add_index     :school_soundex_words, :word
    change_column :school_soundex_words, :word_id, :integer, :null => true
  end

  def self.down
    remove_index  :school_soundex_words, :soundex
    remove_index  :school_soundex_words, :word
    change_column :school_soundex_words, :word_id, :integer, :null => false
  end
end
