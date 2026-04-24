class AddCmsActivityIdToAttemptAndRenameRevision < ActiveRecord::Migration[4.2]
  def self.up
    add_column :attempts, :cms_activity_id, :integer
    rename_column :attempts, :activity_revision_id, :cms_revision_id

    add_index :attempts, :cms_activity_id
    add_index :attempts, :cms_revision_id

    update_query = "UPDATE attempts t INNER JOIN activities a on a.id = t.activity_id set t.cms_activity_id = a.cms_activity_id;"
    ActiveRecord::Base.connection.execute(update_query)
  end

  def self.down
    remove_index :attempts, :cms_activity_id
    remove_index :attempts, :cms_revision_id
  
    remove_column :attempts, :cms_activity_id
    rename_column :attempts, :cms_revision_id, :activity_revision_id
  end
end
