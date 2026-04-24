class DropServiceInstance < ActiveRecord::Migration[4.2]
  def up
    drop_table :service_instances
  end

  def down
    create_table :service_instances do |t|
      t.boolean :current
      t.string  :application
      t.integer :user_count
      t.timestamps
    end
    add_index :service_instances, [:current, :application]
  end
end
