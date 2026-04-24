class RemovePartnerPracticeFromGroupChatRecordings < ActiveRecord::Migration[5.2]
  def change
    safety_assured { remove_column :group_chat_recordings, :partner_practice, :boolean }
  end
end
