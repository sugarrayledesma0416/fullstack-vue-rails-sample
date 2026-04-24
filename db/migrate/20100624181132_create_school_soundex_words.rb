class CreateSchoolSoundexWords < ActiveRecord::Migration[4.2]
  def self.up
    create_table :school_soundex_words do |t|
      t.string :soundex, :limit => 5, :null => false
      t.string :word
      t.integer :school_count
      t.timestamps
    end
  end

  def self.down
    drop_table :school_soundex_words
  end
end
