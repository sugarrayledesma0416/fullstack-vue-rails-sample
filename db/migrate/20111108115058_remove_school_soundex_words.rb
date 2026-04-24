class RemoveSchoolSoundexWords < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "school_soundex_words"
  end

  def self.down
    create_table "school_soundex_words", :force => true do |t|
      t.string   "soundex",      :limit => 5, :null => false
      t.string   "word"
      t.integer  "school_count"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "word_id"
    end

    add_index "school_soundex_words", ["soundex"], :name => "index_school_soundex_words_on_soundex"
    add_index "school_soundex_words", ["word"], :name => "index_school_soundex_words_on_word"
  end
end
