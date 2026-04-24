class AddRoleToCartridgeUserLinks < ActiveRecord::Migration[5.2]
  def change
    add_column :cartridge_user_links, :role, :string
  end
end
