class ChangeCurrentUptoToDate < ActiveRecord::Migration[4.2]
  def self.up
    change_column :sections, :current_upto, :date
  end

  def self.down
    change_column :sections, :current_upto, :datetime
  end
end
