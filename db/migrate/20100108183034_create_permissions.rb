class CreatePermissions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :permissions do |t|
      t.string :label
      t.integer :book_id

      t.timestamps
    end
  end

  def self.down
    drop_table :permissions
  end
end
