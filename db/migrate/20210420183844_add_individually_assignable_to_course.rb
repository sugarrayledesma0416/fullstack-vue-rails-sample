class AddIndividuallyAssignableToCourse < ActiveRecord::Migration[5.2]
  def up
    add_column :courses, :allow_individual_assign, :boolean
    change_column_default :courses, :allow_individual_assign, false
  end

  def down
    remove_column :courses, :allow_individual_assign
  end
end
