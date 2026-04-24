class AddNonNullContraintsToStandardSets < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      change_column_null :standard_sets, :issuer, false
      change_column_null :standard_sets, :name, false
    end
  end
end
