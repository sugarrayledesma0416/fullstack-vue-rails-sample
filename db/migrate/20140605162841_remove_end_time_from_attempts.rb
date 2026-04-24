class RemoveEndTimeFromAttempts < ActiveRecord::Migration[4.2]
  def up
    #remove_column :attempts, :end_time
  end

  def down
    #add_column :attempts, :end_time, :datetime
  end
end
