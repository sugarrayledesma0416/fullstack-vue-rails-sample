class AddSingularLabelToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :singular_label, :string, :default => 'activity'
  end

  def self.down
    remove_column :activities, :singular_label
  end
end
