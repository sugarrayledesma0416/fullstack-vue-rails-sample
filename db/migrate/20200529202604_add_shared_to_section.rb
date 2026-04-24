class AddSharedToSection < ActiveRecord::Migration[5.2]
  def up
    add_column :sections, :shared, :boolean
    change_column_default :sections, :shared, true
  end

  def down
    remove_column :sections, :shared
  end
end
