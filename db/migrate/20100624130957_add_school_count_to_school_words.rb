class AddSchoolCountToSchoolWords < ActiveRecord::Migration[4.2]
  def self.up
    add_column :school_words, :school_count, :integer, :default => 0
  end

  def self.down
    remove_column :school_words, :school_count
  end
end
