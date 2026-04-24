class AddCurrentToScore < ActiveRecord::Migration[4.2]
  def self.up
    add_column :scores, :current, :boolean
  end

  def self.down
    remove_column :scores, :current
  end
end
