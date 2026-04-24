class AddBaseNameToConcepts < ActiveRecord::Migration[4.2]
  def change
    add_column :concepts, :base_name, :string, :null => false, :default => ''
  end
end
