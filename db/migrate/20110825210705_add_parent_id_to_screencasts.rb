class AddParentIdToScreencasts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :screencasts, :parent_id, :integer
  end

  def self.down
    remove_column :screencasts, :parent_id
  end
end
