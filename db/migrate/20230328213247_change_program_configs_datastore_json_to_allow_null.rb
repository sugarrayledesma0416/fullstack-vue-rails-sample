class ChangeProgramConfigsDatastoreJsonToAllowNull < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      # The type of the column didn't change, only allowing null.
      change_column :program_configs, :datastore_json, :text, null: true
    end
  end
end
