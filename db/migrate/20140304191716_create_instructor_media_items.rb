class CreateInstructorMediaItems < ActiveRecord::Migration[4.2]
  def change
    create_table :instructor_media_items do |t|
      t.integer :instructor_id
      t.string :media_type
      t.string :extname
      t.integer :size
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end
end
