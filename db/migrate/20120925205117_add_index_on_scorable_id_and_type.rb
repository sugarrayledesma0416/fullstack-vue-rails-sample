class AddIndexOnScorableIdAndType < ActiveRecord::Migration[4.2]
  def self.up
    add_index :scores, [:scorable_id, :scorable_type], :name => 'scorable'
  end

  def self.down
    remove_index :scores, 'scorable'
  end
end
