class AddCmsIdsToActivity < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :cms_activity_id, :integer
    add_column :activities, :cms_revision_id, :integer
  end

  def self.down
    remove_column :activities, :cms_activity_id
    remove_column :activities, :cms_revision_id
  end
end
