class RemovePasswordAndTimeLimitFromAssignment < ActiveRecord::Migration[4.2]
  def up
    #remove_column :assignments, :password
    remove_column :assignments, :time_limit
  end

  def down
    #add_column :assignments, :password, :string
    add_column :assignments, :time_limit, :integer
  end
end
