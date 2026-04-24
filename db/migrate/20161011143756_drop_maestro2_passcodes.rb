class DropMaestro2Passcodes < ActiveRecord::Migration[4.2]
  def change
    drop_table :maestro2_passcodes
  end
end
