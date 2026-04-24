class AddUploadedAtToResources < ActiveRecord::Migration[4.2]
  def self.up
    add_column :resources, :uploaded_at, :datetime
  end

  def self.down
    remove_column :resources, :uploaded_at
  end
end
