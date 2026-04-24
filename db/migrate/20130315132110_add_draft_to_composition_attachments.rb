class AddDraftToCompositionAttachments < ActiveRecord::Migration[4.2]
  def self.up
    add_column :composition_attachments, :draft, :boolean, :default => true
  end

  def self.down
    remove_column :composition_attachments, :draft
  end
end
