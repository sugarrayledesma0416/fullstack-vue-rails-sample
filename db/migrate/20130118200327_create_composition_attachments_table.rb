class CreateCompositionAttachmentsTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :composition_attachments do |t|
      t.string    :file_name
      t.integer   :user_id
      t.integer   :activity_id
      t.timestamps
    end
  end

  def self.down
    drop_table :composition_attachments
  end
end
