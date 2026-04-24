class SetTimeLimitDefaultToZero < ActiveRecord::Migration[4.2]
  def up
    change_column :assigned_assessment_details, :time_limit, :integer, :default => 0
  end

  def down
    change_column :assigned_assessment_details, :time_limit, :integer
  end
end
