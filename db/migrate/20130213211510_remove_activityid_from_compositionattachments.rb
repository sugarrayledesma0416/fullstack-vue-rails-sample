class RemoveActivityidFromCompositionattachments < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :composition_attachments, :activity_id
  end

  def self.down
    add_column :composition_attachments, :activity_id, :integer
  end
end
