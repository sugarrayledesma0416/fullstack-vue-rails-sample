class ChangeActivityListToTextInWorksets < ActiveRecord::Migration[4.2]
  def self.up
    change_column :worksets, :activity_list, :text
  end

  def self.down
    change_column :worksets, :activity_list, :string
  end
end
