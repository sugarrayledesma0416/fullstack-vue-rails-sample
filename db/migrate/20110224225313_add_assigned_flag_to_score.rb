class AddAssignedFlagToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :assigned, :boolean
  end

  def self.down
    remove_column :scores, :assigned
  end
end
