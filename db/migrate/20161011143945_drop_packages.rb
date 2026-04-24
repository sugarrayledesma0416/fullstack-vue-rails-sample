class DropPackages < ActiveRecord::Migration[4.2]
  def change
    drop_table :packages
  end
end
