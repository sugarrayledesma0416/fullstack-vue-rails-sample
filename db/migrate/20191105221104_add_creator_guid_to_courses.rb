class AddCreatorGuidToCourses < ActiveRecord::Migration[4.2]
  def change
    add_column :courses, :creator_guid, :string, default: nil
    add_index :courses, :creator_guid
  end
end
