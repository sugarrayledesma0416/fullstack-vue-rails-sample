class AddNonNullContraintsToStandards < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column_null :standards, :vendor_standard_set_guid, false
      change_column_null :standards, :description, false
    end
  end
end
