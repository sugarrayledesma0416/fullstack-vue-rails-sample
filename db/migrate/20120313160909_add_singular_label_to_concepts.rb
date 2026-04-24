class AddSingularLabelToConcepts < ActiveRecord::Migration[4.2]
  def self.up
    add_column :concepts, :singular_label, :string, :default => 'activity'
  end

  def self.down
    remove_column :concepts, :singular_label
  end
end
