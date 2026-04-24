class PareDownMaestro2Passcodes < ActiveRecord::Migration[4.2]
  def self.up
    remove_column :maestro2_passcodes, :cart_id
    remove_column :maestro2_passcodes, :date_purchased
    remove_column :maestro2_passcodes, :date_distributed
    remove_column :maestro2_passcodes, :is_distributed
    remove_column :maestro2_passcodes, :distribution_method
    remove_column :maestro2_passcodes, :lit_request_id
  end

  def self.down
    add_column :maestro2_passcodes, :cart_id, :integer
    add_column :maestro2_passcodes, :date_purchased, :datetime
    add_column :maestro2_passcodes, :date_distributed, :datetime
    add_column :maestro2_passcodes, :is_distributed, :boolean
    add_column :maestro2_passcodes, :distribution_method, :string
    add_column :maestro2_passcodes, :lit_request_id, :string
  end
end
