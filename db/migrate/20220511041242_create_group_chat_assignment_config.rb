class CreateGroupChatAssignmentConfig < ActiveRecord::Migration[5.2]
  def change
    create_table :group_chat_assignment_configs do |t|
      t.references :assignment, null: false
      t.integer :group_minimum, null: false
      t.integer :group_maximum, null: false

      t.timestamps
    end
  end
end
