class ChangeNotificationDataField < ActiveRecord::Migration[4.2]
  def up
     change_column :notifications, :data, :text
     add_index :notifications, :activity_id
  end

  def down
     change_column :notifications, :data, :string
     remove_index :notifications, :activity_id
  end
end
