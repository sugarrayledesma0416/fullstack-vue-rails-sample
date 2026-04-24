class AddDisplayNameToStandardSet < ActiveRecord::Migration[6.1]
  def change
    add_column :standard_sets, :display_name, :string, default: ''
  end
end
