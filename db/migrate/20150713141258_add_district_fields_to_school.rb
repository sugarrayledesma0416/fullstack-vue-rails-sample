class AddDistrictFieldsToSchool < ActiveRecord::Migration[4.2]
  def change
    add_column :schools, :district_id, :integer
    add_column :schools, :district_salesforce_id, :integer
  end
end
