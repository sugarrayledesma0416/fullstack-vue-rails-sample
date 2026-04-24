class CreateProgramMediaItems < ActiveRecord::Migration[4.2]
  def self.up
    create_table :program_media_items do |t|
      t.integer  :program_id
      t.integer  :media_item_id
      t.string   :type
    end
  end

  def self.down
    drop_table :program_media_items
  end
end
