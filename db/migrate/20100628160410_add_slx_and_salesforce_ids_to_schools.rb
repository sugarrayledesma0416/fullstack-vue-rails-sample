class AddSlxAndSalesforceIdsToSchools < ActiveRecord::Migration[4.2]
  def self.up
    add_column :schools, :saleslogix_id, :string
    add_column :schools, :salesforce_id, :string
    add_index :schools, :saleslogix_id
    add_index :schools, :salesforce_id
  end

  def self.down
    remove_index :schools, :salesforce_id
    remove_index :schools, :saleslogix_id
    remove_column :schools, :salesforce_id
    remove_column :schools, :saleslogix_id
  end
end
