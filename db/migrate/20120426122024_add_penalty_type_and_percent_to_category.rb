class AddPenaltyTypeAndPercentToCategory < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :late_work_penalty, :string, :default => 'percent_per_day'
    add_column :categories, :penalty_percent, :integer, :default => 5
  end

  def self.down
    remove_column :categories, :late_work_penalty
    remove_column :categories, :penalty_percent
  end
end
