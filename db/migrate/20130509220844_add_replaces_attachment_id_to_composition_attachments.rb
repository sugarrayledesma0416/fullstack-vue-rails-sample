class AddReplacesAttachmentIdToCompositionAttachments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :composition_attachments, :replaces_attachment_id, :integer
  end

  def self.down
    remove_column :composition_attachments, :replaces_attachment_id
  end
end
