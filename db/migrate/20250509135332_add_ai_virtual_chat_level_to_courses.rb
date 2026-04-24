class AddAIVirtualChatLevelToCourses < ActiveRecord::Migration[6.1]
  def up
    add_column :courses, :ai_virtual_chat_level, :boolean, default: false
  end

  def down
    remove_column :courses, :ai_virtual_chat_level
  end
end
