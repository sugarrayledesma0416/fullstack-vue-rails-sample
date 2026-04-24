class AddCleverDistrictIdToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :district_clever_id, :string
  end

  def self.down
    remove_column :schools, :district_clever_id
  end
end
