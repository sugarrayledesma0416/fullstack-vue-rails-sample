class AddIndexToWorksets < ActiveRecord::Migration[4.2]
  def self.up
    add_index :worksets, [:user_id, :section_id], :name => 'user_section'
  end

  def self.down
    remove_index :worksets, :name => 'user_section'
  end
end
