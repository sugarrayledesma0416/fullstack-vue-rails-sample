class AddInputModeToSections < ActiveRecord::Migration[6.1]
  def up
    add_column :sections, :input_mode, :string, default: 'speech'
  end

  def down
    remove_column :sections, :input_mode
  end
end
