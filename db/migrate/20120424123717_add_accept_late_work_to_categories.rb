class AddAcceptLateWorkToCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :accept_late_work, :boolean, :default => true
  end

  def self.down
    remove_column :categories, :accept_late_work
  end
end
