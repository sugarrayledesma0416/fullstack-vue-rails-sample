class ChangeInstructorCreatedActivitiesContentJsonColumn < ActiveRecord::Migration[4.2]
  def up
    # This is just for mysql. If we use postregsql, we can keep text as the column type.
    # http://www.postgresql.org/docs/current/interactive/datatype-character.html
    change_column(:instructor_activity_revisions, :content_json, :mediumtext)
  end

  def down
    change_column(:instructor_activity_revisions, :content_json, :text)
  end
end
