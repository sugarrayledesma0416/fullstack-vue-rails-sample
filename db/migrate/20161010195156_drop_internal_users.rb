class DropInternalUsers < ActiveRecord::Migration[4.2]
  def change
    drop_table :internal_users
  end
end
