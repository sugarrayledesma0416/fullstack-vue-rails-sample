class CreateServiceInstanceTable < ActiveRecord::Migration[4.2]
  def self.up
    create_table :service_instances do |t|
      t.boolean :current
      t.string  :application
      t.integer :user_count
      t.timestamps
    end
    add_index :service_instances, [:current, :application]
  end

  def self.down
    remove_index :service_instances, [:current, :application]
    drop_table :service_instances
  end
end
