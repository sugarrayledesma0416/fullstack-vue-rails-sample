class AddContentJsonToInstructorActivityRevisions < ActiveRecord::Migration[4.2]
  def change
    add_column :instructor_activity_revisions, :content_json, :text 
  end
end
