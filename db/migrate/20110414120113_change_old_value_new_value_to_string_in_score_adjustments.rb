class ChangeOldValueNewValueToStringInScoreAdjustments < ActiveRecord::Migration[4.2]
  def self.up
    change_column :score_adjustments, :old_value, :string
    change_column :score_adjustments, :new_value, :string
  end

  def self.down
    change_column :score_adjustments, :old_value, :integer
    change_column :score_adjustments, :new_value, :integer
  end
end
