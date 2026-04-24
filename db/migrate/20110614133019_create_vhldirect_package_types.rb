class CreateVhldirectPackageTypes < ActiveRecord::Migration[4.2]
  def self.up
    create_table :vhldirect_package_types do |t|
      t.string :package_label, :null => false
      t.string :edelivery_attribute, :null => false
    end
  end

  def self.down
    drop_table :vhldirect_package_types
  end
end
