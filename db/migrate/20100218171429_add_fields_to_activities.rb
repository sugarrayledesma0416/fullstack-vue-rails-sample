class AddFieldsToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :content_filename, :string
  end

  def self.down
    remove_column :activities, :content_filename
  end
end
