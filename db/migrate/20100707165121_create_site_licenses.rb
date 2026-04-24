class CreateSiteLicenses < ActiveRecord::Migration[4.2]
  def self.up
    create_table :site_licenses do |t|
      t.integer :school_id
      t.integer :admin_id
      t.integer :count
      t.string :slx_contact_id
      t.timestamps
    end
  end

  def self.down
    drop_table :site_licenses
  end
end
