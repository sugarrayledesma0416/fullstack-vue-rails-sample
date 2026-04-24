class AddIsEnterpriseToSections < ActiveRecord::Migration[6.1]
  def change
    add_column :sections, :is_enterprise, :boolean, default: false
  end
end
