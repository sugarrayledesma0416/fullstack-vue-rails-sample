class DropProfiles < ActiveRecord::Migration[4.2]
  def change
    drop_table :profiles
  end
end
