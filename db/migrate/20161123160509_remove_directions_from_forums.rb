class RemoveDirectionsFromForums < ActiveRecord::Migration[4.2]
  def up
    remove_column :forums, :directions
  end

  def down
    add_column :forums, :directions, :text
  end
end
