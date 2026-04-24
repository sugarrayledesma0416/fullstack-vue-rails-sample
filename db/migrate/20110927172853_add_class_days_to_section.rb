class AddClassDaysToSection < ActiveRecord::Migration[4.2]
  def self.up
    add_column :sections, :class_days, :string, :default => ''
  end

  def self.down
    remove_column :sections, :class_days
  end
end
