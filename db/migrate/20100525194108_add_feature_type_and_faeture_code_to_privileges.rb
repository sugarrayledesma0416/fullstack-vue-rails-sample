class AddFeatureTypeAndFaetureCodeToPrivileges < ActiveRecord::Migration[4.2]
  def self.up
    add_column :privileges, :feature_type, :string
    add_column :privileges, :feature_code, :string
  end

  def self.down
    remove_column :privileges, :feature_type
    remove_column :privileges, :feature_code
  end
end
