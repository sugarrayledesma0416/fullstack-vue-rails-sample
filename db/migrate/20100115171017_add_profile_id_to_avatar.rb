class AddProfileIdToAvatar < ActiveRecord::Migration[4.2]
  def self.up
    add_column :avatars, :profile_id, :integer
  end

  def self.down
    remove_column :avatars, :profile_id
  end
end
