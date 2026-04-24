class AddResourcesFormTitleToUnits < ActiveRecord::Migration[6.1]
  def change
    add_column :units, :resources_form_title, :string
  end
end
