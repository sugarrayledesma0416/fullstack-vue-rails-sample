class RemoveSchoolWords < ActiveRecord::Migration[4.2]
  def self.up
    drop_table "school_words"
  end

  def self.down
    create_table "school_words", :force => true do |t|
      t.string   "word"
      t.text     "school_id_list"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "school_count",   :default => 0
    end

    add_index "school_words", ["word"], :name => "index_school_words_on_word"
  end
end
