class AddSalesRepIdToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :sales_rep_id , :integer
  end

  def self.down
    remove_column :schools, :sales_rep_id 
  end
end
