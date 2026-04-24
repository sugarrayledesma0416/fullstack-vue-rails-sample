class AddCartridgeToLtiPlatforms < ActiveRecord::Migration[5.2]
  def up
    add_column :lti_platforms, :cartridge, :boolean, default: false
  end

  def down
    remove_column :lti_platforms, :cartridge
  end
end
