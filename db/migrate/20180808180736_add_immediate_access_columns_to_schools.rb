class AddImmediateAccessColumnsToSchools < ActiveRecord::Migration[4.2]
  def change
    add_column :schools, :immediate_access, :boolean, default: false, null: false
    add_column :schools, :immediate_access_start_date, :date
  end
end
