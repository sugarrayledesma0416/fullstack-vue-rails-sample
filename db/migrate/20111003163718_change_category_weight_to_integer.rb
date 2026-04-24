class ChangeCategoryWeightToInteger < ActiveRecord::Migration[4.2]
  def self.up
    change_column :categories, :weighting_percent, :integer
  end

  def self.down
    change_column :categories, :weighting_percent, :float
  end
end
