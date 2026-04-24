class AddDefaultCurrentValueToScore < ActiveRecord::Migration[4.2]
  def self.up
   change_column :scores, :current, :boolean, :default => false
  end

  def self.down
   change_column :scores, :current, :boolean
  end
end
