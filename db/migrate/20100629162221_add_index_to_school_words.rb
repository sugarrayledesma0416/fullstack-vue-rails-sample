class AddIndexToSchoolWords < ActiveRecord::Migration[4.2]
  def self.up
    add_index     :school_words, :word
  end

  def self.down
    remove_index  :school_words, :word
  end
end
