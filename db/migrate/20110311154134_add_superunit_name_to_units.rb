class AddSuperunitNameToUnits < ActiveRecord::Migration[4.2]
  def self.up
    add_column :units, :superunit_name, :string
  end

  def self.down
    remove_column :units, :superunit_name
  end
end
