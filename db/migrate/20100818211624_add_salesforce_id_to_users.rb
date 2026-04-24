class AddSalesforceIdToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :salesforce_id, :string
  end

  def self.down
    remove_column :users, :salesforce_id
  end
end
