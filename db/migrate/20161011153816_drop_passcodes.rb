class DropPasscodes < ActiveRecord::Migration[4.2]
  def change
    drop_table :passcodes
  end
end
