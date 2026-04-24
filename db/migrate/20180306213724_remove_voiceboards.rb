class RemoveVoiceboards < ActiveRecord::Migration[4.2]
  def up
    drop_table :voice_boards
  end

  def down
    create_table "voice_boards", :force => true do |t|
      t.integer  "course_id",                            :null => false
      t.integer  "section_id"
      t.string   "title",                                :null => false
      t.string   "board_type",                           :null => false
      t.boolean  "is_public_view",    :default => false, :null => false
      t.boolean  "is_archived",       :default => false, :null => false
      t.datetime "created_at",                           :null => false
      t.datetime "updated_at",                           :null => false
      t.string   "wimba_resource_id",                    :null => false
    end
  end
end
