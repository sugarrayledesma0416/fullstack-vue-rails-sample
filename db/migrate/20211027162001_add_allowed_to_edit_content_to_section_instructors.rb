class AddAllowedToEditContentToSectionInstructors < ActiveRecord::Migration[5.2]
  def change
    add_column :section_instructors, :allowed_to_edit_content, :boolean, default: true
  end
end
