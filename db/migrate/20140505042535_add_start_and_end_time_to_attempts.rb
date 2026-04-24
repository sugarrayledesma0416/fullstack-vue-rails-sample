class AddStartAndEndTimeToAttempts < ActiveRecord::Migration[4.2]
  def up
    add_column :attempts, :start_time, :datetime
  end

  def down
    remove_column :attempts, :start_time
  end
end
