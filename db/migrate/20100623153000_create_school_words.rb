class CreateSchoolWords < ActiveRecord::Migration[4.2]
  def self.up
    create_table :school_words do |t|
      t.string :word 
      t.text   :school_id_list
      t.timestamps
    end
  end

  def self.down
    drop_table :school_words
  end
end
