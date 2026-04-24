class AddCreditOnlyToCategories < ActiveRecord::Migration[4.2]
  def self.up
    add_column :categories, :credit_only, :boolean, :default => false
  end

  def self.down
    remove_column :categories, :credit_only
  end
end
