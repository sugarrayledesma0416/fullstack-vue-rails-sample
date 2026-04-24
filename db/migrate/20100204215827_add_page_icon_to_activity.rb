class AddPageIconToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :page, :string
    add_column :activities, :icon, :string
  end

  def self.down
    remove_column :activities, :icon
    remove_column :activities, :page
  end
end
