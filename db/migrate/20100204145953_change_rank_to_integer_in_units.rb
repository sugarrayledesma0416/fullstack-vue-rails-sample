class ChangeRankToIntegerInUnits < ActiveRecord::Migration[4.2]
  def self.up
    change_column :units, :rank, :integer
  end

  def self.down
    change_column :units, :rank, :string
  end
end
