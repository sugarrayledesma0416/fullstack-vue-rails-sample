class AddHeightAndWidthToScreencasts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :screencasts, :height, :integer, :default => 480
    add_column :screencasts, :width, :integer, :default => 640
  end

  def self.down
    remove_column :screencasts, :width
    remove_column :screencasts, :height
  end
end
