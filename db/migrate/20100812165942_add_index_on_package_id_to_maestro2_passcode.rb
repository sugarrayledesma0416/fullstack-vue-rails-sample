class AddIndexOnPackageIdToMaestro2Passcode < ActiveRecord::Migration[4.2]
  def self.up
    add_index :maestro2_passcodes, :package_id
  end

  def self.down
    remove_index :maestro2_passcodes, :package_id
  end
end
