class AddPartnerIdToChatErrors < ActiveRecord::Migration[4.2]
  def self.up
    add_column :chat_errors, :partner_id, :integer
  end

  def self.down
    remove_column :chat_errors, :partner_id
  end
end
