class RemoveShareToPortfolioFromSchool < ActiveRecord::Migration[6.1]
  def change
    safety_assured { remove_column :schools, :share_to_portfolio, :boolean }
  end
end
