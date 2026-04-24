class AddShowToSectionInstructor < ActiveRecord::Migration[5.2]
  def up
    add_column :section_instructors, :show, :boolean
    change_column_default :section_instructors, :show, true
  end

  def down
    remove_column :section_instructors, :show
  end
end
