class AddCurrentUptoFieldToSectionsModel < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :current_upto, :timestamp
  end

  def self.down
    remove_column :sections, :current_upto
  end
end
