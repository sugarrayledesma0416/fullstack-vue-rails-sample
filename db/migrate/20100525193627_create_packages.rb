class CreatePackages < ActiveRecord::Migration[4.2]
  def self.up
    create_table :packages do |t|
      t.string :label

      t.timestamps
    end
  end

  def self.down
    drop_table :packages
  end
end
