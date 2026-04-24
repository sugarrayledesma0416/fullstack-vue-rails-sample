class AddDraftToActivities < ActiveRecord::Migration[5.2]
  def up
    add_column :activities, :draft, :boolean
  end

  def down
    remove_column :activities, :draft
  end
end
