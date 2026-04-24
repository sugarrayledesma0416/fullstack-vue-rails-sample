class AddInstructorUploadedToMediaLinks < ActiveRecord::Migration[4.2]
  def self.up
    add_column :media_links, :instructor_uploaded, :boolean
  end

  def self.down
    remove_column :media_links, :instructor_uploaded
  end
end
