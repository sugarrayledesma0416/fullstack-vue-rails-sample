class AddTourGuideToPrograms < ActiveRecord::Migration[6.1]
  def up
    add_column :programs, :tour_guide, :boolean
    change_column_default :programs, :tour_guide, false
  end

  def down
    remove_column :programs, :tour_guide
  end
end
