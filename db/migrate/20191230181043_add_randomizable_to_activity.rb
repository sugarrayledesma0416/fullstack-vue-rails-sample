class AddRandomizableToActivity < ActiveRecord::Migration[5.2]
  def change
    add_column :activities, :randomizable, :boolean
    change_column_default :activities, :randomizable, true
  end

  def down
    remove_column :activities, :randomizable
  end
end
