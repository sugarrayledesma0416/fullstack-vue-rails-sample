class ChangeSchoolsDistrictSfidToString < ActiveRecord::Migration[4.2]
  def up
    change_column :schools, :district_salesforce_id, :string
  end

  def down
    change_column :schools, :district_salesforce_id, :integer
  end
end
