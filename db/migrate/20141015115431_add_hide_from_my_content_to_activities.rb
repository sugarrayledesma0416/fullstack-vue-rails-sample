class AddHideFromMyContentToActivities < ActiveRecord::Migration[4.2]
  def change
    add_column :activities, :hide_from_my_content, :boolean, :default => false
  end
end
