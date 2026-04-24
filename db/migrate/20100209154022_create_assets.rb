class CreateAssets < ActiveRecord::Migration[4.2]
  def self.up
    create_table :assets do |t|
      t.string  :category

      t.timestamps
    end
  end

  def self.down
    drop_table :assets
  end
end
