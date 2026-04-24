class AddProgramIdToAsset < ActiveRecord::Migration[4.2]
  def self.up
    add_column :assets, :program_id, :integer
  end

  def self.down
    remove_column :assets, :program_id
  end
end
