class AddDueTimeToSection < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :due_time, :time
  end

  def self.down
    remove_column :sections, :due_time
  end
end
