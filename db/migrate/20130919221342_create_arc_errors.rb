class CreateArcErrors < ActiveRecord::Migration[4.2]
  def self.up
    create_table :arc_errors do |t|
      t.references :user
      t.string :error_message
      t.string :error_type
      t.string :flash_version
      t.string :browser
      t.string :browser_version
      t.string :platform
      t.string :http_referer
      t.timestamps
    end
  end

  def self.down
    drop_table :arc_errors
  end
end
