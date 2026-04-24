class AddComponentNameToActivities < ActiveRecord::Migration[4.2]
  def self.up
    add_column :activities, :component_name, :string
  end

  def self.down
    remove_column :activities, :component_name
  end
end
